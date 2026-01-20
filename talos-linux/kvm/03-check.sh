#!/usr/bin/bash

function check_net(){
    todo=true
    while ${todo};
    do
      ret=$(virsh domifaddr ${host_check} 2>/dev/null | awk '/ipv4/ {print $4}')
      [[ -n ${ret} ]] && export todo=false
      echo "Waiting Start VM...${host_check}"
      sleep 3
    done
    echo "Vms Done"
}

for i in "control-plane" "worker-node";
do
  export _ip=$(virsh domifaddr ${i} 2>/dev/null | awk '/ipv4/ {print $4}')
  
  if [[ -z ${_ip} ]]
  then 
    export host_check=${i}
    check_net
  else
   printf "VM: %-15s => IP: %-20s\n" "${i}" "${_ip}"
  fi
done

