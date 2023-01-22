@echo off

call :create_folder monitoring
call :create_folder monitoring\dashboard
call :create_folder monitoring\prometheus
call :create_folder root
call :create_folder root\config
call :create_folder root\config\cl
call :create_folder root\config\el

call :download_file monitoring/dashboard/agora-chain-dashboard.json
call :download_file monitoring/prometheus/config.yml
call :download_file root/config/cl/chain-config.yaml
call :download_file root/config/cl/config.yaml
call :download_file root/config/el/config.toml
call :download_file root/config/el/genesis.json
call :download_file agora.bat
call :download_file agora.sh
call :download_file docker-compose.yml
call :download_file docker-compose-monitoring.yml

goto :end

:create_folder
if not exist %~1 (
    mkdir %~1
)
goto :end

:download_file
curl https://raw.githubusercontent.com/bosagora/agora-chain/testnet/%~1 -f -s -S -L -o %~1
goto :end

:end
