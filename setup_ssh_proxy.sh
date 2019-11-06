function info() {
  echo "[INFO] $*"
}

pgrep ncat &> /dev/null
if [ $? ]
then
  info 'Killing old ncat processes'
  pkill ncat
fi

for i in {1..8}
do
  router="R$i"
  ncat --keep-open --sh-exec "exec sudo ip netns exec $router nc localhost 22" -l 222$i &
  info "Proxy for $router launched."
done
