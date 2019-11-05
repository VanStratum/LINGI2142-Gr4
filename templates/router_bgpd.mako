<%doc>
this file generate the bgpd.conf file for each router.
In order to generate the file a json file containing the name of router have to be 
created with the following attribute:
	1] name : must contain the name of the router
	2] rnum : must contain the identifier of the router
</%doc>
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
  address-family ipv6 unicast
  	neighbor fde4:4:f000:1::${data['ibgp_neighbor'][i]} activate
	neighbor fde4:4:f000:1::${data['ibgp_neighbor'][i]} next-hop-self
	neighbor fde4:4:f000:1::${data['ibgp_neighbor'][i]} update-source fde4:4:f000:1::${data['rnum']}
  exit-address-family
% endfor
%endif
% if 'RouteReflector_client' in data.keys():
<% client = data['RouteReflector_client'] %>
% for c in client:
! Route reflector client : fde4:4:f000:1::${c}
  neighbor fde4:4:f000:1::${c} remote-as 65004
  address-family ipv6 unicast
	neighbor fde4:4:f000:1::${c} activate
	neighbor fde4:4:f000:1::${c} next-hop-self
	neighbor fde4:4:f000:1::${c} update-source fde4:4:f000:1::${data['rnum']}
	neighbor fde4:4:f000:1::${c} route-reflector-client
  exit-address-family
% endfor
% endif
% endif
