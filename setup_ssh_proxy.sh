function info() {
  echo "[INFO] $*"
}

pgrep ncat &> /dev/null
if [ $? ]
then
  info 'Killing old ncat processes'
  pkill ncat
fi


routers=(R1 R2 R3 R4 R5 R6 R7 R8)
for router in ${routers[@]}
do
  rid=$(echo $router | sed -e 's/R//g')
  ncat --keep-open --sh-exec "exec sudo ip netns exec $router nc localhost 22" -l 222$rid &
  info "Proxy for $router launched."
done
