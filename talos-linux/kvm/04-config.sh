#!/usr/bin/bash

export control_plane=$(virsh domifaddr  control-plane | egrep '/' | awk '{print $4}' | cut -d/ -f1)
export worker_node=$(virsh domifaddr worker-node | egrep '/' | awk '{print $4}' | cut -d/ -f1)

talosctl get disks --nodes ${control_plane} --insecure
talosctl gen config my-talos-cluster https://${control_plane}:6443 --install-disk /dev/vda -o configs/ --force
talosctl apply-config --insecure --nodes ${control_plane} --file configs/controlplane.yaml
talosctl apply-config --insecure --nodes ${worker_node} --file configs/worker.yaml
echo "Sleep 15..."
sleep 15