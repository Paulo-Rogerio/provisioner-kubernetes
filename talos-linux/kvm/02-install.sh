#!/usr/bin/env bash

function install()
{
  sudo virt-install \
    --virt-type kvm \
    --name $1 \
    --ram $2 \
    --vcpus $3 \
    --disk path=/var/lib/libvirt/images/$1.qcow2,bus=virtio,size=50,format=qcow2 \
    --cdrom /var/lib/libvirt/images/metal-amd64.iso \
    --os-variant linux2022 \
    --network network=my-talos-net \
    --boot hd,cdrom \
    --cpu host-passthrough \
    --noautoconsole
}

# Call
params "control-plane" 2048 3
params "worker-node" 4096 4
