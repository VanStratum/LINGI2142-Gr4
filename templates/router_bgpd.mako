% if 'bgp_iface' in data.keys() or 'ibgp_neighbor' in data.keys():
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
! ebgp session with ${data['bgp_neighbor']} on interface ${data['bgp_iface']}
  neighbor ${data['bgp_neighbor']} remote-as ${data['bgp_up1_as']}
  neighbor ${data['bgp_neighbor']} interface ${data['bgp_iface']}
  address-family ipv6 unicast
    neighbor ${data['bgp_neighbor']} activate
    network fde4:4::/32
  exit-address-family
% endif
% if 'ibgp_neighbor' in data.keys():
 <% r = range(0,len(data['ibgp_neighbor'])) %>
  % for i in r:
! ibgp session with fde4:4:f000:1::${data['ibgp_neighbor'][i]} 
  neighbor fde4:4:f000:1::${data['ibgp_neighbor'][i]} remote-as 65004
% endfor
  address-family ipv6 unicast
  % for i in r:
  	neighbor fde4:4:f000:1::${data['ibgp_neighbor'][i]} activate
	neighbor fde4:4:f000:1::${data['ibgp_neighbor'][i]} next-hop-self
	neighbor fde4:4:f000:1::${data['ibgp_neighbor'][i]} update-source fde4:4:f000:1::${data['rnum']}
  % endfor
  exit-address-family
% endif
% endif
