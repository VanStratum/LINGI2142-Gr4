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
sudo chmod 600 id_rsa
./setup_ssh_proxy.sh

if [ $1 -eq 1 ]
then
  info "Waiting 30 seconds for the network booting before launching the tests"
  sleep 30
  python3 test/test_main.py
fi

info "End of startup script"
