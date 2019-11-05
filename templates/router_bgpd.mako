% if 'bgp_iface' in data.keys() or 'ibgp_iface' in data.keys():
!
! BGP conf file for ${data['name']}
!
hostname ${data['name']}
password zebra
service advanced-vty
! log stdout
debug 
!
router bgp ${data['bgp_self_as']}
bgp router-id 1.0.0.${data['rnum']}
  no bgp default ipv4-unicast
% if 'bgp_iface' in data.keys():
  neighbor ${data['bgp_neighbor']} remote-as ${data['bgp_up1_as']}
  neighbor ${data['bgp_neighbor']}  interface ${data['bgp_iface']}
% endif
% if 'ibgp_iface' in data.keys():
 <% r = range(0,len(data['ibgp_iface'])) %>
  % for i in r:
! ibgp session with ${data['ibgp_neighbor'][i]} on interface ${data['ibgp_iface'][i]}
  neighbor ${data['ibgp_neighbor'][i]} remote-as 65004
  neighbor ${data['ibgp_neighbor'][i]} interface ${data['ibgp_iface'][i]}
% endfor
  address-family ipv6 unicast
  % for i in r:
  	neighbor ${data['ibgp_neighbor'][i]} activate
	neighbor ${data['ibgp_neighbor'][i]} next-hop-self
  % endfor
  exit-address-family
% endif
% if 'bgp_iface' in data.keys():
  address-family ipv6 unicast
    neighbor ${data['bgp_neighbor']} activate
    network fde4:4::/32
  exit-address-family
% endif
% endif
