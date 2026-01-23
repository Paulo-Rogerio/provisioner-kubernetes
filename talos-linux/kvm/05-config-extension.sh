#!/usr/bin/bash

export control_plane=$(virsh domifaddr  control-plane | egrep '/' | awk '{print $4}' | cut -d/ -f1)
export worker_node=$(virsh domifaddr worker-node | egrep '/' | awk '{print $4}' | cut -d/ -f1)
export cluster="prgs-talos"
export talos_version=$(awk '/Tag:/ {print $2}' <<< $(talosctl version --client)) 

echo "============================="
echo "Control Plane  : ${control_plane}"
echo "Worker Node    : ${worker_node}"
echo "Cluster Name   : ${cluster}"
echo "Talos Version  : ${talos_version}"
echo "============================="
echo

mkdir -p configs

cat > configs/schematic.yaml <<EOF
customization:
    systemExtensions:
        officialExtensions:
            - siderolabs/iscsi-tools
            - siderolabs/util-linux-tools
            - siderolabs/gvisor
            - siderolabs/qemu-guest-agent
            - siderolabs/nfs-utils            
EOF

export id=$(curl -sSL -X POST --data-binary @configs/schematic.yaml https://factory.talos.dev/schematics | jq -r '.id')

echo "==============================="
echo "${id}"
echo "==============================="

talosctl gen config ${cluster} https://${control_plane}:6443 \
    --install-image=factory.talos.dev/installer/${id}:${talos_version} \
    --install-disk /dev/vda \
    --output configs/ \
    --force

talosctl apply-config \
  --insecure \
  --nodes ${control_plane} \
  --file configs/controlplane.yaml

talosctl apply-config \
  --insecure \
  --nodes ${worker_node} \
  --file configs/worker.yaml

echo "Sleep 10..."
sleep 10
