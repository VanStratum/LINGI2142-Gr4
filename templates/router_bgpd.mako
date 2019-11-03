% if 'bgp_iface' in data.keys():
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
bgp router-id 1.0.0.1
  no bgp default ipv4-unicast
  neighbor fde4::1 remote-as ${data['bgp_up1_as']}
  neighbor fde4::1 interface ${data['bgp_iface']}
  address-family ipv6 unicast
    neighbor fde4::1 activate
    network fde4:4::/32
  exit-address-family
% endif
