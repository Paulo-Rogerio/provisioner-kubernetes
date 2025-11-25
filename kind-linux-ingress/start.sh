#!/usr/bin/env bash

export red="\033[0;31m"
export yellow="\033[33m"
export endColor="\033[0m"

cd $(dirname $0)

read -p "Informe o Nome do Cluster: " clusterName

if [[ -z ${clusterName} ]]
then
    echo -e "${red} Cluster Name não informado. ${endColor}"
    exit 1;
fi

echo -e "${yellow} Start ClusterName ${clusterName} ${endColor}" 

export clusterName

envsubst < k8s/cluster.yaml > k8s/tmp/cluster.yaml

sh k8s/create-cluster.sh
