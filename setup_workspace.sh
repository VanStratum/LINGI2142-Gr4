#! /usr/bin/env bash

# Downloading some build scripts given in the project startup. This step avoid counting those
# scripts as contributions of us and ensure the use of the provided scripts.

SCRIPT_DIR='.'
declare -A SCRIPTS=( 
  ['create_network.sh']='2d34f3e444e2e8723babfe407891efbf070ac77c'
  ['connect_to.sh']='6afdaca013f46a037b00567a8a669dfb675d3fd5' 
  ['cleanup.sh']='1ac153ae7e644dd29d11195e91d460fce82e2b2f'
  ['_node_utils.sh']='f92c0ab697fd5e34a75dd3b726b041ee7d6dc418'
  ['templating_example/make_router_conf.py']='7de54bfeac4c7b673bfe04786d3bb8cd902e9358'
)

check_script() {
  echo $HASH $CURRENT_SCRIPT | sha1sum -c
}

download_script() {
  wget -P $SCRIPT_DIR 'https://raw.githubusercontent.com/cnp3/CampusNetwork/isp_net/'$script \
    && check_script
}

manage_scripts() {
  for script in ${!SCRIPTS[@]}
  do
    # Derive the script name from github path
    IFS='/' read -ra SCRIPT_PATH <<< $script 
    HASH=${SCRIPTS[$script]}
    CURRENT_SCRIPT=$SCRIPT_DIR'/'${SCRIPT_PATH[-1]}
    if [ -f $CURRENT_SCRIPT ]
    then
      if [ check_script ]
      then
        echo $script' exists. Nothing to do.'
        continue
      else
        echo 'Script exists but hash differ. Downloading expected version.'
        rm $CURRENT_SCRIPT
      fi
    fi
    download_script || exit 1
    chmod +x $CURRENT_SCRIPT
  done
} 

manage_scripts

