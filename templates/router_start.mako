#! /bin/bash

# Startup script for router ${data['name']}

ldconfig

% if data['rnum'] != "-1":
<% loopback_addr = 'fde4:4:f000:1::%x' % int(data['rnum']) %>
ip -6 addr add ${loopback_addr}/128 dev lo
% endif 

<% generic_iface = '%s-eth' % data['name'] %>
% for iface in data['ifaces']['routing']: 
  <% 
    dev = '%s%s' % (generic_iface, loop.index)
    subnet = iface[0] 
  %> 
ip link set dev ${dev} up
ip -6 addr add fde4:4:f000::${subnet}/127 dev ${dev}
% endfor

<% lan_iface = '%s-lan' % data['name'] %>
% if data['rnum'] == "-1":
<% lan_iface = generic_iface %>
% endif
% for iface in data['ifaces']['lan']: 
  <% 
    dev = '%s%s' % (lan_iface, loop.index)
    subnet = iface
  %> 
ip link set dev ${dev} up
ip -6 addr add fde4:4:f000:${subnet} dev ${dev}
% endfor

# zebra is required to make the link between all FRRouting daemons
# and the linux kernel routing table
LD_LIBRARY_PATH=/usr/local/lib /usr/lib/frr/zebra -A 127.0.0.1 -f /etc/${data['name']}_zebra.conf -z /tmp/${data['name']}.api -i /tmp/${data['name']}_zebra.pid --v6-rr-semantics &

% if data['rnum'] != "-1":
# launching FRRouting OSPF daemon
LD_LIBRARY_PATH=/usr/local/lib /usr/lib/frr/ospf6d -f /etc/${data['name']}_ospf.conf -z /tmp/${data['name']}.api -i /tmp/${data['name']}_ospf6d.pid -A 127.0.0.1 &
% endif

% if "bgp" in data.keys():
% if "e" in data['bgp'].keys():
<% ebgp = data['bgp']['e'] %>
#configuring the bgp interfaces
% for iface in ebgp['ifaces']:
ip link set dev ${iface} up
ip -6 addr add ${ebgp['iface_ip'][loop.index]}/64 dev ${iface} 
% endfor
% endif
#lauching FRRouting BGP daemon
LD_LIBRARY_PATH=/usr/local/lib /usr/lib/frr/bgpd -f /etc/${data['name']}_bgpd.conf -z /tmp/${data['name']}.api -i /tmp/${data['name']}_bgpd.pid -A 127.0.0.1 &
% endif

# Launching nftables firewall
LD_LIBRARY_PATH=/usr/local/lib nft -f /etc/${data['name']}_nftables.conf
