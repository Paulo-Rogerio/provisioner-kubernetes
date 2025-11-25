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

[[ $(kind get clusters) == "${clusterName}" ]] || kind create cluster --config=tmp/cluster.yaml
check_pod_running

echo "Install Metallb..."
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install metallb metallb/metallb --namespace metallb-system --create-namespace
check_pod_running

# CIDR Metallb
echo "Apply Metallb..."
./metallb.sh

helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm upgrade --install --namespace kube-system --create-namespace metrics-server metrics-server/metrics-server -f values/metric-server.yaml
check_pod_running

# Gateway-API ( CDR )
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml
check_pod_running

# Fabric Nginx
helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --namespace nginx-gateway \
  --create-namespace \
  --set nginx.service.type=LoadBalancer
check_pod_running  

kubectl apply -f example.yaml
check_pod_running

loadBalancerIP=$(kubectl get gateway gateway --output jsonpath='{.status.addresses[*].value}')

echo
echo "---------------------"
echo
curl ${loadBalancerIP}/foo
echo
echo "---------------------"
echo

kubectl delete -f example.yaml

# Clean tmp files
rm tmp/cluster.yaml
rm tmp/metallb.yaml
