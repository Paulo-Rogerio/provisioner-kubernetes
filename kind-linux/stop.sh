#!/usr/bin/env bash
cd $(dirname $0)

kind delete cluster -n $(kind get clusters)

