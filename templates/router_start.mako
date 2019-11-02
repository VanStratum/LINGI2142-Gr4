#! /bin/bash

# Startup script for router ${data['name']}

ldconfig

ip -6 addr add fde4:4:f000:1::${data['rnum']}/128 dev lo

<% r = range(0,data['n_iface']) %>
% for i in r: 
<% 
    iface = 'eth%s'%str(i) 
    key = '%s-subnet'%iface
    dev = '%s-%s'%(data['name'],iface)
    subnet = data[key] 
%> 
ip link set dev ${dev} up
ip -6 addr add fde4:4:f000::${subnet}/127 dev ${dev}
% endfor

# zebra is required to make the link between all FRRouting daemons
# and the linux kernel routing table
LD_LIBRARY_PATH=/usr/local/lib /usr/lib/frr/zebra -A 127.0.0.1 -f /etc/${data['name']}_zebra.conf -z /tmp/${data['name']}.api -i /tmp/${data['name']}_zebra.pid &
# launching FRRouting OSPF daemon
LD_LIBRARY_PATH=/usr/local/lib /usr/lib/frr/ospf6d -f /etc/${data['name']}_ospf.conf -z /tmp/${data['name']}.api -i /tmp/${data['name']}_ospf6d.pid -A 127.0.0.1

% if "bgp_iface" in data.keys():
#  ip -6 addr add dev ${data['bgp_iface']} $data['bgp_iface_ip']}
#  LD_LIBRARY_PATH=/usr/local/lib /usr/lib/frr/bgp -f /etc/${data['name']}_bgpd.conf -z /tmp/${data['name']}.api -i /tmp/${data['name']}_bgpd.pid -A 127.0.0.1 &
% endif

