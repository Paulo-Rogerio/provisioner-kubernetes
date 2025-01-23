#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# disable swap 
sudo swapoff -a
sudo sed -i '/swap.img/d' /etc/fstab
sudo ln -svf /bin/bash /bin/sh
sudo timedatectl set-timezone ${TIMEZONE_VMS}

