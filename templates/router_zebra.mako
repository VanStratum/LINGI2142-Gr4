! -*- zebra -*-
!
! zebra sample configuration file
!
hostname ${data['name']}
password zebra
enable password zebra
!
! Interface's description.
!
interface lo
 description loopback.
!
interface lo1
 description lo1.
!
% for iface in data['ifaces']:
<% dev = '%s-eth%s' % (data['name'], loop.index) %>
interface ${dev}
 description Link to ${dev}
!
% endfor
