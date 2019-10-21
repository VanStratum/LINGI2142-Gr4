info () {
  echo -e "\n[INFO] $*"
}

info "Setting up the workspace"
./setup_workspace.sh

info "Cleaning potential old network"
sudo ./cleanup.sh

info "Generating configuration files for each router"
sudo ./gen_conf.py

info "Creating network"
sudo ./create_network.sh isp4_topo

sleep 1

info "Launching tests"
sudo ./test/test.sh
