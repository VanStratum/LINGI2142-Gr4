<%doc>
this file generate the bgpd.conf file for each router.
In order to generate the file a json file containing the name of router have to be 
created with the following  mandatory attribute:
	1] name : must contain the name of the router
	2] rnum : must contain the identifier of the router
	3] bgp_self_as: the as of the routeur	

=================================== ebgp session =========================================
If the routeur have to do a ebgp session the following attribute are mandatory:

	4] bgp_iface: if specify it means the router make a ebgp session on the specify interface
	5] bgp_iface_ip: must be specify if bgp_iface is specified, IP addresses use for the ebgp session
	note: a routeur can only make one ebgp session
	6] bgp_neighbor : addresse of the ebgp peer
	7] bgp_up1_as : as of the peer

=================================== ibgp session =========================================
if the routeur make ibgp session the following attribute are mandatory:
	8] ibgp_neighbor : a list of all neighbor with who the routeur make a ibgp session

=================================== route reflector session ===============================
if the routeur is a route reflector the following attribute are mandatory:
	9] RouteReflector_client: a list of all the client
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
 <% neighbor = data['ibgp_neighbor'] %>
  % for n in neighbor:
! ibgp session with fde4:4:f000:1::${n} 
  neighbor fde4:4:f000:1::${n} remote-as 65004
  address-family ipv6 unicast
  	neighbor fde4:4:f000:1::${n} activate
	neighbor fde4:4:f000:1::${n} next-hop-self
	neighbor fde4:4:f000:1::${n} update-source fde4:4:f000:1::${data['rnum']}
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
