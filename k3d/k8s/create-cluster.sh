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

[[ $(k3d cluster list -o json | jq -r '.[].name') == "${clusterName}" ]] || k3d cluster create --config=tmp/cluster.yaml
check_pod_running


echo "Install Metallb..."
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install metallb metallb/metallb --namespace metallb-system --create-namespace
check_pod_running

# CIDR Metallb
echo "Apply Metallb..."
./metallb.sh

#
# Clean tmp files
rm tmp/cluster.yaml
rm tmp/metallb.yaml
