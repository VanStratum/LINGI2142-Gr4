% if data['rnum'] != "-1":
! OSPF conf file for ${data['name']}
!
hostname ${data['name']}
password zebra
! log stdout
service advanced-vty
!
debug ospf6 neighbor state
!
% for type in data['ifaces']:
%   for iface in data['ifaces'][type]:
%     if type == "routing":
<%      rule = "eth"  %>
%     elif type == "lan":
<%      rule = "lan" %>
% endif
interface ${data['name']}-${rule}${loop.index}
  ipv6 ospf6 cost 1
  ipv6 ospf6 hello-interval 10
  ipv6 ospf6 dead-interval 40
  ipv6 ospf6 instance-id 0
  ipv6 ospf6 network point-to-point
!
% endfor
% endfor
interface lo
  ipv6 ospf6 cost 1
  ipv6 ospf6 hello-interval 10
  ipv6 ospf6 dead-interval 40
  ipv6 ospf6 instance-id 0
!
router ospf6
    ospf6 router-id 255.251.23.${data['rnum']}
% for type in data['ifaces']:
%   for iface in data['ifaces'][type]:
%     if type == "routing":
<%      rule = "eth"  %>
%     elif type == "lan":
<%      rule = "lan"  %>
% endif
    interface ${data['name']}-${rule}${loop.index} area 0.0.0.0
    % endfor
    % endfor
    interface lo area 0.0.0.0
    redistribute connected
!
% endif
