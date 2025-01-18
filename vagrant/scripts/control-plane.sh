#!/usr/bin/env bash

NODENAME=$(hostname -s)
VAGRANT_FILE="/vagrant-files/configs"

sudo kubeadm config images pull

echo "Preflight Check Passed: Downloaded All Required Images"

sudo kubeadm init \
    --apiserver-advertise-address=${IP_CONTROL_PLANE} \
    --apiserver-cert-extra-sans=${IP_CONTROL_PLANE} \
    --pod-network-cidr=${POD_CIDR} \
    --service-cidr=${SERVICE_CIDR} \
    --node-name ${NODENAME} 

mkdir -p /home/vagrant/.kube
sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown vagrant:vagrant -R /home/vagrant/.kube

if [[ -d ${VAGRANT_FILE} ]]; 
then
   sudo rm -f ${VAGRANT_FILE}/*
else
   sudo mkdir -p /vagrant-files/configs
   sudo chown -R vagrant:vagrant /vagrant-files
fi

sudo cp -i /etc/kubernetes/admin.conf ${VAGRANT_FILE}/config
touch ${VAGRANT_FILE}/join.sh
chmod +x ${VAGRANT_FILE}/join.sh       
echo "sudo $(kubeadm token create --print-join-command)" > ${VAGRANT_FILE}/join.sh
