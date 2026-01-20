#!/usr/bin/bash

sudo virsh destroy control-plane
sudo virsh undefine control-plane --remove-all-storage
sudo virsh destroy worker-node
sudo virsh undefine worker-node --remove-all-storage
sudo virsh net-destroy --network my-talos-net
sudo virsh net-undefine --network my-talos-net
rm -f configs/*
