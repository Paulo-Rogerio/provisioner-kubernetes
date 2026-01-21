#!/usr/bin/env bash

cd $(dirname $0)

for i in $(find . -maxdepth 1 -type f -name '[0-9]*' | sort);
do
  eval $i
done
