#!/bin/bash

function create_folder() {
  mkdir -p "$@"
}

function download_file() {
  wget https://raw.githubusercontent.com/bosagora/agora-chain/testnet/$@ -O $@
}

create_folder monitoring
create_folder monitoring/dashboard
create_folder monitoring/prometheus
create_folder root
create_folder root/config
create_folder root/config/cl
create_folder root/config/el

download_file monitoring/dashboard/agora-chain-dashboard.json
download_file monitoring/prometheus/config.yml
download_file root/config/cl/chain-config.yaml
download_file root/config/cl/config.yaml
download_file root/config/el/config.toml
download_file root/config/el/genesis.json
download_file agora.bat
download_file agora.sh
download_file docker-compose.yml
download_file docker-compose-monitoring.yml

chmod 755 agora.sh
