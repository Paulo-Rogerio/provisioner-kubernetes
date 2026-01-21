#!/usr/bin/env bash

function output(){
  echo $(date +%Y-%m-%d-%H:%M:%S) - $@
}


export cidr=$(virsh domifaddr control-plane 2>/dev/null | awk '/ipv4/ {print $4}' | egrep -o '[0-9]+.[0-9]+.[0-9]+.[0-9]+/[0-9]+')
output "Kind CIDR..........: ${cidr}"

export cidr_short=$(cut -d '.' -f1-3 <<< ${cidr})
output "CIDR short.........: ${cidr_short}"

envsubst < metallb.yaml > tmp/metallb.yaml

kubectl apply -f tmp/metallb.yaml
