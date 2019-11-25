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
<%! import re %>
% if 'bgp' in data.keys():
  <% bgp = data['bgp'] %>
!
! BGP conf file for ${data['name']}
!
hostname ${data['name']}
password zebra
service advanced-vty
! log stdout
debug 
!

<% routeur_loopback = '%x' % int(data['rnum'])%>
! filter export to provider
ipv6 prefix-list provider permit fde4:4::/32

!========== Route-Map ========================
! setup route-map and communities
route-map provider-policy-in permit 10
   set community 1
route-map provider-policy-out deny 10
   match community 1
route-map provider-policy-out permit 20
! route-map for customer
route-map cust-policy-in permit 10
   set community cust
   set local-preference 500
route-map cust-policy-in permit 20
! route-map for share cost
route-map share-policy-in permit 10
   set community share
   set local-preference 400
route-map share-policy-in permit 20

!============ communities =====================
! bgp community for provider
bgp community-list standard 1 deny 65004:200
!bgp community for the customer
bgp community-list cust permit 1:2500
!bgp community for the share cost
bgp community-list share permit 1:2400

router bgp ${bgp['self_as']}
bgp router-id 1.0.0.${data['rnum']}
  no bgp default ipv4-unicast
% if 'e' in bgp.keys():
  <% ebgp = bgp['e'] %>
% for iface in ebgp['ifaces']:
  <% 
    neighbor = ebgp['neighbors'][loop.index] 
    up1_as = ebgp['up1_as'][loop.index]
  %>
! ebgp session with ${neighbor} on interface ${iface}
  neighbor ${neighbor} remote-as ${up1_as}
<% pwd = ebgp['pwd'][loop.index] %>
% if pwd != "":
  neighbor ${neighbor} password ${pwd}
% endif
  neighbor ${neighbor} interface ${iface}
  address-family ipv6 unicast
    neighbor ${neighbor} activate
    network fde4:4::/32
% if 'is_provider' in ebgp.keys():
    neighbor ${neighbor} prefix-list provider out
%endif
% if (int(data['rnum']) == 11 or int(data['rnum']) == 9): 
    neighbor ${neighbor} route-map provider-policy-in in 
% elif (int(data['rnum']) == 10):
    neighbor ${neighbor} route-map  cust-policy-in in
% elif (int(data['rnum']) == 14):
    neighbor ${neighbor} route-map share-policy-in in
%endif
    neighbor ${neighbor} route-map provider-policy-out out
  exit-address-family
% endfor
% endif
% if 'i' in bgp.keys():
  <% ibgp = bgp['i'] %>
  % for ne in ibgp['neighbors']:
    <% 
      n = '%x' % int(ne)
      dec = int(n, 16)
      r1 = "R%s" % ("0%s" % dec if dec < 10 else dec)
      r2 = data['name']
      replace = "%s%s" % ((r1, r2) if r1 < r2 else (r2, r1))
      pwd = re.sub('REPLACEME', replace, ibgp['pwd'][loop.index])
    %>
! ibgp session with fde4:4:f000:1::${n} 
  neighbor fde4:4:f000:1::${n} remote-as 65004
  neighbor fde4:4:f000:1::${n} password ${pwd}
  address-family ipv6 unicast
  	neighbor fde4:4:f000:1::${n} activate
	neighbor fde4:4:f000:1::${n} next-hop-self
	neighbor fde4:4:f000:1::${n} update-source fde4:4:f000:1::${routeur_loopback}
  exit-address-family
% endfor
%endif
% if 'rr_clients' in bgp.keys():
<% rr = bgp['rr_clients'] %>
% for cl in rr['clients']:
<% 
  c = '%x' % int(cl) 
  dec = int(c, 16)
  r1 = "R%s" % ("0%s" % dec if dec < 10 else dec)
  r2 = data['name']
  replace = "%s%s" % ((r1, r2) if r1 < r2 else (r2, r1))
  pwd = re.sub('REPLACEME', replace, rr['pwd'][loop.index])
%>
! Route reflector client : fde4:4:f000:1::${c}
  neighbor fde4:4:f000:1::${c} remote-as 65004
  neighbor fde4:4:f000:1::${c} password ${pwd}
  address-family ipv6 unicast
	neighbor fde4:4:f000:1::${c} activate
	neighbor fde4:4:f000:1::${c} next-hop-self
	neighbor fde4:4:f000:1::${c} route-reflector-client
	neighbor fde4:4:f000:1::${c} update-source fde4:4:f000:1::${routeur_loopback}
  exit-address-family
% endfor
% endif
% endif
