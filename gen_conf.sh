#! /bin/bash

TEMPLATES_DIR='templates/'
CONFIG_DIR='network_cfg/'

A=($(ls -p $TEMPLATES_DIR))
for directory in ${A[*]}
do
  d1=$TEMPLATES_DIR$directory
  echo 'Entering' $d1
  template=$d1$(ls $d1 | grep '.mako')
  echo '=> Template :' $template
  B=($(ls -p $d1))
  for f in ${B[*]}
  do
    if [ $(echo $d1$f | grep '.json') ]
    then
      in=$d1$f
      out=$CONFIG_DIR$(echo $f | sed -e 's/.json//g')
      ./make_router_conf.py -i $in -t $template -o $out
      echo "$out generated"
      chmod +x $out
    fi
  done
done
