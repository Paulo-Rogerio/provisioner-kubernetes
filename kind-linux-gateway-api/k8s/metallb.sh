#!/usr/bin/env bash

cd $(dirname $0)

function output(){
  echo $(date +%Y-%m-%d-%H:%M:%S) - $@
}

export kind_cidr=$(docker network inspect -f '{{.IPAM.Config}}' kind | egrep -o '[0-9]{1,}.[0-9]{1,}.[0-9].[0-9]/[0-9]{1,}')
output "Kind CIDR..........: ${kind_cidr}"

export kind_cidr_short=$(cut -d '.' -f1-3 <<< ${kind_cidr})
output "CIDR short.........: ${kind_cidr_short}"

envsubst < metallb.yaml > tmp/metallb.yaml

kubectl apply -f tmp/metallb.yaml
