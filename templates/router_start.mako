#! /bin/bash

# Startup script for router ${data['name']}

ldconfig

ip -6 addr add fde4:4:f000:1::${data['rnum']}/128 dev lo

<% generic_iface = '%s-eth' % data['name'] %>
% for iface in data['ifaces']: 
  <% 
    dev = '%s%s' % (generic_iface, loop.index)
    subnet = iface[0] 
  %> 
ip link set dev ${dev} up
ip -6 addr add fde4:4:f000::${subnet}/127 dev ${dev}
% endfor

# zebra is required to make the link between all FRRouting daemons
# and the linux kernel routing table
LD_LIBRARY_PATH=/usr/local/lib /usr/lib/frr/zebra -A 127.0.0.1 -f /etc/${data['name']}_zebra.conf -z /tmp/${data['name']}.api -i /tmp/${data['name']}_zebra.pid --v6-rr-semantics &

# launching FRRouting OSPF daemon
LD_LIBRARY_PATH=/usr/local/lib /usr/lib/frr/ospf6d -f /etc/${data['name']}_ospf.conf -z /tmp/${data['name']}.api -i /tmp/${data['name']}_ospf6d.pid -A 127.0.0.1 &

% if "bgp" in data.keys():
% if "e" in data['bgp'].keys():
<% ebgp = data['bgp']['e'] %>
#configuring the bgp interfaces
% for iface in ebgp['ifaces']:
ip link set dev ${iface} up
ip -6 addr add ${ebgp['iface_ip'][loop.index]}/64 dev ${iface} 
% endfor
% endif
% endif
#lauching FRRouting BGP daemon
LD_LIBRARY_PATH=/usr/local/lib /usr/lib/frr/bgpd -f /etc/${data['name']}_bgpd.conf -z /tmp/${data['name']}.api -i /tmp/${data['name']}_bgpd.pid -A 127.0.0.1 &
