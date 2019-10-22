#! /bin/bash

# Startup script for router ${data['name']}

ldconfig

#ip link add link lo name lo1 type dummy
#ip link set dev lo1 up
#ip -6 addr add fde4:4:10::${data['rnum']}${data['rnum']}/128 dev lo1

<% r = range(0,data['n_iface']) %>
% for i in r: 
<% 
    iface = 'eth%s'%str(i) 
    key = '%s-subnet'%iface
    dev = '%s-%s'%(data['name'],iface)
    subnet = data[key] 
%> 
ip -6 addr add fde4:4:${subnet}::${data['rnum']}${data['rnum']}${data['rnum']}${data['rnum']}/128 dev lo
ip link set dev ${dev} up
ip -6 addr add fde4:4:${subnet}::${data['rnum']}${data['rnum']}/64 dev ${dev}

% endfor

#iface0=${data['name']}-eth0


#iface1=${data['name']}-eth1

#ip link set dev $iface1 up
#ip -6 addr add fde4:4:${data['eth1-subnet']}::${data['rnum']}${data['rnum']}/64 dev $iface1

# zebra is required to make the link between all FRRouting daemons
# and the linux kernel routing table
LD_LIBRARY_PATH=/usr/local/lib /usr/lib/frr/zebra -A 127.0.0.1 -f /etc/${data['name']}_zebra.conf -z /tmp/${data['name']}.api -i /tmp/${data['name']}_zebra.pid &
# launching FRRouting OSPF daemon
LD_LIBRARY_PATH=/usr/local/lib /usr/lib/frr/ospf6d -f /etc/${data['name']}_ospf.conf -z /tmp/${data['name']}.api -i /tmp/${data['name']}_ospf6d.pid -A 127.0.0.1
