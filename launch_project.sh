info () {
  echo -e "\n[INFO] $*"
}

known_hosts="/home/vagrant/.ssh/known_hosts"
if [ -f $known_hosts ]
then
  info "Cleaning ssh known_hosts"
  rm $known_hosts
fi

info "Setting up the workspace"
./setup_workspace.sh

info "Cleaning potential old network"
sudo ./cleanup.sh

info "Generating configuration files for each router"
sudo ./gen_conf.py

info "Creating network"
sudo ./create_network.sh isp4_topo

info "Launching ssh proxies"
./setup_ssh_proxy.sh

sleep 5

info "Launching tests"
sudo ./test/test.sh
