@ECHO OFF
FOR /F "tokens=* USEBACKQ" %%F IN (`curl -s https://ifconfig.me/ip`) DO (
SET P2P_HOST_IP=%%F
)

SetLocal EnableDelayedExpansion & REM All variables are set local to this run & expanded at execution time rather than at parse time (tip: echo !output!)

REM Complain if invalid arguments were provided.

if "%~1"=="" (
  goto printError
)
for %%a in (el-node cl-node validator upgrade docker-compose docker-compose-monitoring) do (
    if %1 equ %%a (
        goto validprocess
    )
)
:printError
echo [31mERROR: PROCESS missing or invalid[0m
echo Usage: ./agora.bat PROCESS FLAGS.
echo.
echo PROCESS can be el-node, cl-node, validator, docker-compose.
echo FLAGS are the flags or arguments passed to the PROCESS.
echo.
exit /B 1
:validprocess

if not exist "root" (
    call :create_folder root
    call :create_folder root\config
    call :create_folder root\config\cl
    call :create_folder root\config\el
    call :download_file root/config/cl/chain-config.yaml
    call :download_file root/config/cl/config.yaml
    call :download_file root/config/el/config.toml
    call :download_file root/config/el/genesis.json
    call :download_file agora.bat
    call :download_file agora.sh
    call :download_file docker-compose.yml
    call :download_file docker-compose-monitoring.yml
)

if not exist "monitoring" (
    call :create_folder monitoring
    call :create_folder monitoring\dashboard
    call :create_folder monitoring\prometheus
    call :download_file monitoring/dashboard/agora-chain-dashboard.json
    call :download_file monitoring/prometheus/config.yml
)


















































if "%~1"=="upgrade" (

    curl -f -s -S -L -o upgrade.bat https://raw.githubusercontent.com/bosagora/agora-chain/devnet/upgrade.bat
    call upgrade.bat

) else if "%~1"=="el-node" (

    if "%~2"=="init" (

        if exist .\root\chain\el (
          RD /S /Q .\root\chain\el
        )

        docker run -it ^
        -v %cd%:/agora-chain ^
        --name el-node --rm  ^
        bosagora/agora-el-node:agora_v1.12.0-66e599  ^
        --datadir=/agora-chain/root/chain/el  ^
        init /agora-chain/root/config/el/genesis.json

     ) else if "%~2"=="run" (

        docker run -it ^
        -v %cd%:/agora-chain ^
        -p 6060:6060 -p 8545:8545 -p 30303:30303 -p 30303:30303/udp ^
        --name el-node --rm  ^
        bosagora/agora-el-node:agora_v1.12.0-66e599  ^
        --config=/agora-chain/root/config/el/config.toml ^
        --datadir=/agora-chain/root/chain/el ^
        --syncmode=full --metrics --metrics.addr=0.0.0.0 --metrics.port=6060

     ) else if "%~2"=="run" (

        docker run -it ^
        -v %cd%:/agora-chain ^
        --name el-node-attach --rm ^
        bosagora/agora-el-node:agora_v1.12.0-66e599 ^
        --config=/agora-chain/root/config/el/config.toml ^
        --datadir=/agora-chain/root/chain/el ^
        attach /agora-chain/root/chain/el/geth.ipc

    ) else (

        echo FLAGS are the flags or arguments passed to the PROCESS.
        echo [31mFLAGS '%~2' is not found![0m
        echo [31mUsage: ./agora.bat el-node FLAGS.[0m
        echo [31mFLAGS can be init, run[0m
        exit /B 1

    )

) else if "%~1"=="cl-node" (

    if "%~2"=="run" (

        docker run -it ^
        -v %cd%:/agora-chain ^
        -p 3500:3500 -p 4000:4000 -p 8080:8080 -p 13000:13000 -p 12000:12000/udp ^
        --name cl-node --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-node:agora_v4.0.5-ceb45d ^
        --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml ^
        --config-file=/agora-chain/root/config/cl/config.yaml ^
        --p2p-host-ip=%P2P_HOST_IP% ^
        --monitoring-port=8080 ^
        --checkpoint-sync-url=https://mainnet-sync.bosagora.org ^
        --genesis-beacon-api-url=https://mainnet-sync.bosagora.org

    ) else (

        echo [31mFLAGS '%~2' is not found![0m
        echo [31mUsage: ./agora.bat cl-node FLAGS.[0m
        echo [31mFLAGS can be run[0m
        exit /B 1

    )

) else if "%~1"=="validator" (

    if "%~2"=="import" (

        if "%~3"=="" (

            echo [31mUsage: ./agora.bat validator import keys-dir.[0m
            echo [31mkeys-dir is the path to a directory where keystores to be imported are stored[0m
            exit /B 1

        ) else (

            docker run -it ^
            -v %cd%:/agora-chain ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
            accounts import ^
            --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml ^
            --keys-dir=/agora-chain/%~3 ^
            --wallet-dir=/agora-chain/root/wallet

        )

    ) else if "%~2"=="run" (

        docker run -it ^
          -v %cd%:/agora-chain ^
          -p 8081:8081 ^
          --network="host" ^
          --name cl-validator --rm ^
          --platform linux/amd64 ^
          bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
          --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml ^
          --config-file=/agora-chain/root/config/cl/config.yaml ^
          --datadir=/agora-chain/root/chain/cl/ ^
          --accept-terms-of-use ^
          --wallet-dir=/agora-chain/root/wallet ^
          --proposer-settings-file=/agora-chain/root/config/cl/proposer_config.json ^
          --wallet-password-file=/agora-chain/root/config/cl/password.txt ^
          --monitoring-port=8081

    ) else if "%~2"=="accounts" (

        if "%~3"=="import" (

            if "%~4"=="" (

                echo [31mUsage: ./agora.bat validator accounts import keys-dir.[0m
                echo [31mkeys-dir is the path to a directory where keystores to be imported are stored[0m
                exit /B 1

            ) else (

                docker run -it ^
                -v %cd%:/agora-chain ^
                --name cl-validator --rm ^
                --platform linux/amd64 ^
                bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
                accounts import ^
                --accept-terms-of-use ^
                --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml ^
                --keys-dir=/agora-chain/%~4 ^
                --wallet-dir=/agora-chain/root/wallet

            )

        ) else if "%~3"=="list" (

            docker run -it ^
            -v %cd%:/agora-chain ^
            --network=host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
            accounts list ^
            --accept-terms-of-use ^
            --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml ^
            --wallet-dir=/agora-chain/root/wallet

        ) else if "%~3"=="backup" (

            if "%~4"=="" (
                SET DATA_FOLDER="backup-wallet"
                ECHO "Default backup folder is %DATA_FOLDER%"
            ) else (
                SET DATA_FOLDER="%~4"
            )

            if exist %cd%\%DATA_FOLDER% (
              RD /S /Q %cd%\%DATA_FOLDER%
            )

            docker run -it ^
            -v %cd%:/agora-chain ^
            --network=host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
            accounts backup ^
            --accept-terms-of-use ^
            --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml ^
            --wallet-dir=/agora-chain/root/wallet ^
            --wallet-password-file=/agora-chain/root/config/cl/password.txt ^
            --backup-dir=/agora-chain/%DATA_FOLDER%

        ) else (

            echo [31mFLAGS '%~3' is not found![0m
            echo [31mUsage: ./agora.bat validator accounts FLAGS.[0m
            echo [31mFLAGS can be import, list, voluntary-exit, backup [0m
            exit /B 1

        )

    ) else if "%~2"=="exit" (

        docker run -it ^
        -v %cd%:/agora-chain ^
        --net bosagora_network ^
        --name cl-ctl --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-ctl:agora_v4.0.5-ceb45d ^
        validator exit ^
        --wallet-dir=/agora-chain/root/wallet ^
        --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml ^
        --beacon-rpc-provider=node1-2-cl:4000 ^
        --accept-terms-of-use ^
        --wallet-password-file=/agora-chain/root/config/cl/password.txt

    ) else if "%~2"=="generate-bls-to-execution-change" (

        if "%~3"=="" (
            SET BLS2EXEC_DATA_FOLDER="bls_to_execution_changes"
            ECHO "Default data folder is %BLS2EXEC_DATA_FOLDER%"
        ) else (
            SET BLS2EXEC_DATA_FOLDER="%~3"
        )

        if exist %cd%\%BLS2EXEC_DATA_FOLDER% (
          RD /S /Q %cd%\%BLS2EXEC_DATA_FOLDER%
        )

        docker run -it ^
        -v %cd%:/agora-chain ^
        --name deposit-ctl --rm ^
        bosagora/agora-deposit-cli:agora_v2.5.0-1839d2 ^
        --language=english ^
        generate-bls-to-execution-change ^
        --bls_to_execution_changes_folder=/agora-chain/%BLS2EXEC_DATA_FOLDER% ^
        --chain=devnet

    ) else if "%~2"=="withdraw" (

        if "%~3"=="" (
            SET BLS2EXEC_DATA_FOLDER="bls_to_execution_changes"
            ECHO "Default data folder is %BLS2EXEC_DATA_FOLDER%"
        ) else (
            SET BLS2EXEC_DATA_FOLDER="%~3"
        )

        docker run -it ^
        -v %cd%:/agora-chain ^
        --net bosagora_network ^
        --name cl-ctl --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-ctl:agora_v4.0.5-ceb45d ^
        validator withdraw ^
        --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml ^
        --config-file=/agora-chain/root/config/cl/config.yaml ^
        --beacon-node-host=http://node1-2-cl:3500 ^
        --accept-terms-of-use ^
        --confirm ^
        --path=/agora-chain/%BLS2EXEC_DATA_FOLDER%

    ) else if "%~2"=="slashing-protection-history" (

        if "%~3"=="export" (

            if "%~4"=="" (
                SET DATA_FOLDER="slashing-protection-export"
                ECHO "Default slashing protection history folder is %DATA_FOLDER%"
            ) else (
                SET DATA_FOLDER="%~4"
            )

            if exist %cd%\%DATA_FOLDER% (
              RD /S /Q %cd%\%DATA_FOLDER%
            )

            docker run -it ^
            -v %cd%:/agora-chain ^
            --network=host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
            slashing-protection-history export ^
            --accept-terms-of-use ^
            --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml ^
            --datadir=/agora-chain/root/chain/cl/ ^
            --slashing-protection-export-dir=/agora-chain/%DATA_FOLDER%

         ) else if "%~3"=="import" (

            if "%~4"=="" (
                SET DATA_FOLDER="slashing-protection-export"
                ECHO "Default slashing protection history folder is %DATA_FOLDER%"
            ) else (
                SET DATA_FOLDER="%~4"
            )

            docker run -it ^
            -v %cd%:/agora-chain ^
            --network=host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
            slashing-protection-history import ^
            --accept-terms-of-use ^
            --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml ^
            --datadir=/agora-chain/root/chain/cl/ ^
            --slashing-protection-json-file=/agora-chain/%DATA_FOLDER%/slashing_protection.json

        ) else (

            echo [31mFLAGS '%~3' is not found![0m
            echo [31mUsage: ./agora.bat validator slashing-protection-history FLAGS.[0m
            echo [31mFLAGS can be import, export [0m
            exit /B 1

        )

    ) else if "%~2"=="wallet" (

        if "%~3"=="create" (

            docker run -it ^
            -v %cd%:/agora-chain ^
            --network=host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
            wallet create ^
            --accept-terms-of-use ^
            --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml ^
            --wallet-dir=/agora-chain/root/wallet

        ) else (

            echo [31mFLAGS '%~3' is not found![0m
            echo [31mUsage: ./agora.bat validator wallet FLAGS.[0m
            echo [31mFLAGS can be create [0m
            exit /B 1

        )

    ) else (

        echo [31mFLAGS '%~2' is not found![0m
        echo [31mUsage: ./agora.bat validator FLAGS.[0m
        echo [31mFLAGS can be run, accounts, wallet[0m
        exit /B 1

    )

) else if "%~1"=="docker-compose" (

    if "%~2"=="up" (

        docker-compose -f docker-compose.yml up -d

    ) else if "%~2"=="down" (

        docker-compose -f docker-compose.yml down

    ) else (

        echo [31mFLAGS '%~2' is not found![0m
        echo [31mUsage: ./agora.bat docker-compose FLAGS.[0m
        echo [31mFLAGS can be up down[0m
        exit /B 1

    )

) else if "%~1"=="docker-compose-monitoring" (

    if "%~2"=="up" (

        docker-compose -f docker-compose-monitoring.yml up -d

    ) else if "%~2"=="down" (

        docker-compose -f docker-compose-monitoring.yml down

    ) else (

        echo [31mFLAGS '%~2' is not found![0m
        echo [31mUsage: ./agora.bat docker-compose-monitoring FLAGS.[0m
        echo [31mFLAGS can be up down[0m
        exit /B 1

    )

) else (

    echo [31mProcess '%~1' is not found![0m
    echo [31mUsage: ./agora.bat PROCESS FLAGS.[0m
    echo [31mPROCESS can be el-node, cl-node, validator, docker-compose, docker-compose-monitoring[0m
    exit /B 1

)
goto :end

:create_folder
if not exist %~1 (
    mkdir %~1
)
goto :end

:download_file
curl https://raw.githubusercontent.com/bosagora/agora-chain/devnet/%~1 -f -s -S -L -o %~1
goto :end

:end
