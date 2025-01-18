#!/usr/bin/env bash

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

kubectl taint nodes master-1 node-role.kubernetes.io/control-plane-

echo "Install Metric-Server..."
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm upgrade --install --namespace kube-system --create-namespace metrics-server metrics-server/metrics-server -f /vagrant-files/values/metric-server.yaml
check_pod_running


echo "Install Metallb..."
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install metallb metallb/metallb --namespace metallb-system --create-namespace
check_pod_running

# Apply Manifests
for i in $(ls /vagrant-files/manifests/);
do
  kubectl apply -f /vagrant-files/manifests/${i}
  check_pod_running
done

