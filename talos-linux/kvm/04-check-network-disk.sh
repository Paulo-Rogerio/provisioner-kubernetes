#!/usr/bin/bash

export control_plane=$(virsh domifaddr  control-plane | egrep '/' | awk '{print $4}' | cut -d/ -f1)
export worker_node=$(virsh domifaddr worker-node | egrep '/' | awk '{print $4}' | cut -d/ -f1)

echo $control_plane
echo "========================================="
echo
talosctl get disks --nodes ${control_plane} --insecure

echo "========================================="
echo
talosctl get links --nodes ${control_plane} --insecure

echo "========================================="
echo
talosctl get links --nodes ${worker_node} --insecure 

