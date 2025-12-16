#!/usr/bin/env bash
cd $(dirname $0)

k3d cluster delete $(k3d cluster list -o json | jq -r '.[].name')

