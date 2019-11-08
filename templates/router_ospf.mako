!
! OSPF conf file for ${data['name']}
!
hostname ${data['name']}
password zebra
! log stdout
service advanced-vty
!
debug ospf6 neighbor state
!
<%  r = range(0,data['n_iface']) %>
% for iface in r:
interface ${data['name']}-eth${iface}
  ipv6 ospf6 cost 1
  ipv6 ospf6 hello-interval 10
  ipv6 ospf6 dead-interval 40
  ipv6 ospf6 instance-id 0
  ipv6 ospf6 network point-to-point
!
% endfor
interface lo
  ipv6 ospf6 cost 1
  ipv6 ospf6 hello-interval 10
  ipv6 ospf6 dead-interval 40
  ipv6 ospf6 instance-id 0
!
router ospf6
    ospf6 router-id 255.251.23.${data['rnum']}
    % for iface in r:
    interface ${data['name']}-eth${iface} area 0.0.0.0
    % endfor
    interface lo area 0.0.0.0
    redistribute connected
!
