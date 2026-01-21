#!/usr/bin/bash

cat > my-talos-net.xml <<EOF
<network>
  <name>my-talos-net</name>
  <bridge name="talos-bridge" stp="on" delay="0"/>
  <forward mode='nat'>
    <nat/>
  </forward>
  <ip address="10.0.0.1" netmask="255.255.255.0">
    <dhcp>
      <range start="10.0.0.2" end="10.0.0.100"/>
    </dhcp>
  </ip>
</network>
EOF

sudo virsh net-define my-talos-net.xml
sudo virsh net-start my-talos-net
sudo virsh net-autostart my-talos-net
sudo virsh net-info my-talos-net
rm -f my-talos-net.xml
