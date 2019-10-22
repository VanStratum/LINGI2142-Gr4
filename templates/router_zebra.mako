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
<% r = range(0,data['n_iface']) %>
% for i in r:
<% name = 'eth%s-subnet'%i %>
interface ${data['name']}-eth${i}
 description Link to R${data[name]}
!
% endfor
