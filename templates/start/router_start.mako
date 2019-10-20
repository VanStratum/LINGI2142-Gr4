#! /bin/bash

# Startup script for router ${data['name']}

ldconfig

iface0=${data['name']}-eth0

ip link set dev $iface0 up
ip -6 addr add fde4:4:${data['eth0-subnet']}::${data['rnum']}${data['rnum']}/64 dev $iface0

iface1=${data['name']}-eth1

ip link set dev $iface1 up
ip -6 addr add fde4:4:${data['eth1-subnet']}::${data['rnum']}${data['rnum']}/64 dev $iface1


