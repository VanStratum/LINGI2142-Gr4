#!/bin/bash

sysctl -w net.ipv6.conf.all.forwarding=1
sysctl -w net.ipv6.conf.default.forwarding=1

if [ ! -d /etc/ssh ]; then
	mkdir /etc/ssh
fi
mv /etc/sshd_config /etc/ssh
mv /etc/authorized_keys /etc/ssh
chown -R root:root /etc
until dpkg-reconfigure openssh-server &> /dev/null
do
  sleep 5
done
mkdir -p /var/run/sshd
/usr/sbin/sshd -o PidFile="/tmp/sshd-${data['name']}.pid"
