#!/usr/bin/env bash

cd $(dirname $0)

function check_pod_running(){
    todo=true
    while ${todo};
    do
      podsWorking=$(kubectl get pod -A -o custom-columns="STATUS:.status.phase" | grep -v STATUS | egrep -vc "Running|Succeeded")
      [[ ${podsWorking} == 0 ]] && export todo=false
      echo "Waiting Pod Health..."
      sleep 10
    done
    echo "Pods Running"
}

[[ -n $(docker ps -f "name=kind-registry" -f "status=running" -q) ]] || 
{
 docker run -d \
  --restart=always \
  -p 5000:5000 \
  -v $(pwd)/registry.yml:/etc/docker/registry/config.yml \
  --name kind-registry \
  registry:2
}

echo "***********************************************************************"
echo "* Install Metallb                                                     *"
echo "***********************************************************************"
echo
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install metallb metallb/metallb --namespace metallb-system --create-namespace
check_pod_running

# CIDR Metallb
./metallb.sh

echo "***********************************************************************"
echo "* Install Metrics Server                                              *"
echo "***********************************************************************"
echo
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm upgrade --install --namespace kube-system --create-namespace metrics-server metrics-server/metrics-server -f values/metric-server.yaml
check_pod_running

# Gateway-API ( CDR )
echo "***********************************************************************"
echo "* Install CRD                                                         *"
echo "***********************************************************************"
echo
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml
check_pod_running

# Fabric Nginx
echo "***********************************************************************"
echo "* Install Nginx Fabric                                                *"
echo "***********************************************************************"
echo
helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --namespace nginx-gateway \
  --create-namespace \
  --set nginx.service.type=LoadBalancer
check_pod_running  

echo "***********************************************************************"
echo "* Install Deployments Test                                            *"
echo "***********************************************************************"
echo
kubectl apply -f example.yaml
check_pod_running

loadBalancerIP=$(kubectl get gateway gateway --output jsonpath='{.status.addresses[*].value}')

echo
echo "---------------------"
echo
curl ${loadBalancerIP}/foo
echo
echo "---------------------"

echo "***********************************************************************"
echo "* Remove Deployments Test                                             *"
echo "***********************************************************************"
echo
kubectl delete -f example.yaml

# Clean tmp files
rm tmp/cluster.yaml
rm tmp/metallb.yaml


echo "***********************************************************************"
echo "* Deployment ArgoCD                                                   *"
echo "***********************************************************************"
echo

kubectl neat <<< $(kubectl create ns argocd --dry-run=client -o yaml) | kubectl apply -f -

cp /home/paulo/Documents/Estudos/Estudos-Certbot/docker-compose/letsencrypt/prgs-corp.xyz/fullchain1.pem certs/tls.crt
cp /home/paulo/Documents/Estudos/Estudos-Certbot/docker-compose/letsencrypt/prgs-corp.xyz/privkey1.pem certs/tls.key

kubectl create secret tls argocd-tls \
  --cert=certs/tls.crt \
  --key=certs/tls.key \
  --namespace=argocd --dry-run=client -o yaml | kubectl apply -f -

rm -f certs/tls.crt
rm -f certs/tls.key

cat > values/values-argocd.yaml <<EOF
global:
  domain: argocd.prgs-corp.xyz

configs:
  params:
    server.insecure: true
EOF


helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm search repo argo/argo-cd --versions | head -n 10
helm upgrade \
  --install \
  --namespace argocd \
  --create-namespace argo-cd argo/argo-cd \
  --version 9.1.8 \
  -f values/values-argocd.yaml

check_pod_running
kubectl apply -f gateway-api-argocd.yaml

echo "Run: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d | xargs" 
