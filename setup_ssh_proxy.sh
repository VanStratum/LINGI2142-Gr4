#! /bin/bash

info() {
  echo "[INFO] $*"
}

pgrep ncat &> /dev/null
if [ $? ]
then
  info 'Killing old ncat processes'
  pkill ncat
fi

for i in {01..14}
do
  router="R$i"
  ncat --keep-open --sh-exec "exec sudo ip netns exec $router nc localhost 22" -l 22$i &
  info "Proxy for $router launched."
done
