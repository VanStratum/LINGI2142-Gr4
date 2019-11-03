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
  neighbor fde4::1 remote-as ${data['bgp_up1_as']}
  neighbor fde4::1 interface ${data['bgp_iface']}
% endif
% if 'ibgp_iface' in data.keys():
 <% r = range(0,len(data['ibgp_iface'])) %>
  % for i in r:
! ibgp session with ${data['ibgp_neighbor'][i]} on interface ${data['ibgp_iface'][i]}
    neighbor ${data['ibgp_neighbor'][i]} remote-as 65004
    neighbor ${data['ibgp_neighbor'][i]} interface ${data['ibgp_iface'][i]}
    neighbor ${data['ibgp_neighbor'][i]} activate
% endfor
% endif
  address-family ipv6 unicast
    neighbor fde4::1 activate
    network fde4:4::/32
  exit-address-family
% endif
