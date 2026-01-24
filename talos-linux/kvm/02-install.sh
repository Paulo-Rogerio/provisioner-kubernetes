#!/usr/bin/env bash

function install()
{
  export name=$1
  export ram=$2
  export vcpu=$3
  export ip=$4
  export type=$5
  export mac=$6

  sudo virt-install \
    --virt-type kvm \
    --name ${name} \
    --ram ${ram} \
    --vcpus ${vcpu} \
    --disk path=/var/lib/libvirt/images/${name}.qcow2,bus=virtio,size=50,format=qcow2 \
    --disk path=/var/lib/libvirt/images/${name}-data.qcow2,bus=virtio,size=5,format=qcow2 \
    --cdrom /var/lib/libvirt/images/metal-amd64.iso \
    --os-variant linux2022 \
    --network network=my-talos-net,mac=${mac} \
    --boot hd,cdrom \
    --cpu host-passthrough \
    --noautoconsole

  network

  sudo virsh \
    net-update my-talos-net add-last ip-dhcp-host \
    "<host mac='${mac}' name='${name}' ip='${ip}'/>" \
    --live --config

}

function network() {
cat > configs/${type}-net.yaml <<EOF
machine:
  type: ${type}
  network:
    interfaces:
      - interface: enp1s0
        addresses: 
          - ${ip}/24
        routes:
          - network: 0.0.0.0/0
            gateway: 10.0.0.1
    nameservers:
      - 8.8.8.8
      - 4.2.2.2
EOF
}

gen_mac() {
  printf '52:54:00:%02x:%02x:%02x\n' \
    $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

# Call
install "control-plane" 2048 3 "10.0.0.10" "controlplane" $(gen_mac)
install "worker-node" 4096 4 "10.0.0.11" "worker" $(gen_mac)
