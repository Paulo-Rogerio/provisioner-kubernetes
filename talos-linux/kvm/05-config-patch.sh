#!/usr/bin/bash

export control_plane=$(virsh domifaddr  control-plane | egrep '/' | awk '{print $4}' | cut -d/ -f1)
export worker_node=$(virsh domifaddr worker-node | egrep '/' | awk '{print $4}' | cut -d/ -f1)

# talosctl gen config my-talos-cluster https://${control_plane}:6443 --install-disk /dev/vda -o configs/ --force
# talosctl apply-config --insecure --nodes ${control_plane} --file configs/controlplane.yaml
# talosctl apply-config --insecure --nodes ${worker_node} --file configs/worker.yaml

talosctl gen config prgs-cluster https://${control_plane}:6443 \
  --install-disk /dev/vda \
  --output configs/ \
  --force

talosctl machineconfig patch \
  configs/controlplane.yaml \
  --patch @configs/controlplane-net.yaml \
  --output configs/controlplane-net-patch.yaml

talosctl machineconfig patch \
  configs/worker.yaml \
  --patch @configs/worker-net.yaml \
  --output configs/worker-net-patch.yaml

talosctl apply-config \
  --insecure \
  --nodes ${control_plane} \
  --file configs/controlplane-net-patch.yaml

talosctl apply-config \
  --insecure \
  --nodes ${worker_node} \
  --file configs/worker-net-patch.yaml

echo "Sleep 10..."
sleep 10
