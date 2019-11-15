#!/bin/sh

sudo apt-get update
sudo apt install -y nmap linux-headers-4.9-amd64 linux-image-4.9-amd64 asciidoc libgmp-dev
sudo apt-get autoremove -y

mkdir /tmp/repos

cd /tmp/repos

git clone https://git.netfilter.org/libmnl/
cd libmnl
sh autogen.sh
./configure
make
sudo make install
cd ..

git clone https://git.netfilter.org/libnftnl/
cd libnftnl
sh autogen.sh
./configure
make
sudo make install
cd ..

git clone https://git.netfilter.org/nftables/
cd nftables
sh autogen.sh
./configure
make
sudo make install
cd ..

sudo /sbin/ldconfig
export PATH=$PATH:/usr/local/sbin

