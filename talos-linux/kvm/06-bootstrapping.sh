#!/usr/bin/bash

export TALOSCONFIG=$(realpath configs/talosconfig)
export control_plane=$(virsh domifaddr control-plane | egrep '/' | awk '{print $4}' | cut -d/ -f1)
export worker_node=$(virsh domifaddr worker-node | egrep '/' | awk '{print $4}' | cut -d/ -f1)

function check_talos(){
    todo=true
    while ${todo};
    do
      nc ${control_plane} 50000 -vz
      [[ $? -eq 0 ]] && export todo=false
      echo "Waiting Talos...."
      sleep 3
    done
    echo "Talos Done"
}

function health_talos() {
  local target="waiting for all k8s nodes to report schedulable: OK"
  
  talosctl --nodes ${control_plane} health > /tmp/talos.txt 2>&1
  todo=true
  while ${todo};
  do
    local output="$(cat /tmp/talos.txt)"
    grep -q "${target}" <<< ${output}

    if [[ $? -eq 0 ]]
    then
      export todo=false
    else
      echo "Waiting Talos Heath...."
      sleep 5
      talosctl --nodes ${control_plane} health > /tmp/talos.txt 2>&1      
    fi
  done
  sleep 5
  echo "Cluster Heath"
}

function heath_etcd() {
  
  todo=true
  while ${todo};
  do
    count="$(talosctl --nodes ${control_plane} get members | grep -c Member)"

    if [[ ${count} -eq "2" ]]
    then
      export todo=false
    else
      echo "Waiting Etcd Heath...."
      sleep 5
      export count="$(talosctl --nodes ${control_plane} get members | grep -c Member)"
    fi
  done
  echo "Cluster Etcd Heath"

}

function generate_kubeconfig() {
  [[ -f "configs/kubeconfig" ]] || talosctl --nodes ${control_plane} kubeconfig configs/kubeconfig
}

nc ${control_plane} 50000 -vz 2&> /dev/null
[[ $? -ne 0 ]] && check_talos

echo "======================================="
echo " Control Plane: ${control_plane}"
echo " Worker Node  : ${worker_node}"
echo 

echo "======================================="
echo " Config Nodes"
echo "======================================="
talosctl config nodes ${control_plane} ${worker_node}
talosctl config info
talosctl config endpoints ${control_plane}

echo 
echo "======================================="
echo " Check Etcd"
echo "======================================="
heath_etcd
echo 

echo "======================================="
echo " Bootstrap"
echo "======================================="
echo "Running => talosctl --nodes ${control_plane} bootstrap"
talosctl --nodes ${control_plane} bootstrap
echo

echo "======================================="
echo " Check Heath K8S Talos"
echo "======================================="
health_talos
echo

echo "======================================="
echo " Gera Kubeconfig"
echo "======================================="
generate_kubeconfig
export KUBECONFIG=$PWD/configs/kubeconfig
kubectl get nodes -o wide
cp configs/kubeconfig ~/.kube/config
echo 

echo "======================================="
echo " Done"
echo "======================================="

