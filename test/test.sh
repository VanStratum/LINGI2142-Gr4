#! /bin/bash

if [[ "$UID" != "0" ]]; then
    echo "This script must be run as root!"
    exit 1
fi

CONFIGDIR=$(pwd)/network_cfg
source _node_utils.sh

ERRORS=0

declare -A test_array=(
  ['R1-eth0']='fde4:4:1::22'
  ['R1-eth1']='fde4:4:4::44'
  ['R2-eth0']='fde4:4:1::11'
  ['R2-eth1']='fde4:4:2::33'
  ['R3-eth0']='fde4:4:2::22'
  ['R3-eth1']='fde4:4:3::44'
  ['R4-eth0']='fde4:4:3::33'
  ['R4-eth1']='fde4:4:4::11'
)

test_p2p_connectivity() {
  for router in R1 R2 R3 R4
  do
    echo -e '#####################'
    echo -e '# Testing node : '$router' #'
    echo -e '#####################\n'
    for iface in -eth0 -eth1
    do
      riface=$router$iface
      node_exec_command $router 'ping6 -I '$riface' -c 1 '${test_array[$riface]} | grep '1 received' > /dev/null
      if [ $? == 0 ]
      then
        code='OK:'
      else
        code='ERROR:'
        ((ERRORS++))
      fi
      echo $code $riface '->' ${test_array[$riface]}
    done
    echo -e '\n\n'
  done
}

test_p2p_connectivity

echo $ERRORS 'error(s)'
