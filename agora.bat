@ECHO OFF
FOR /F "tokens=* USEBACKQ" %%F IN (`curl -s https://ifconfig.me/ip`) DO (
SET P2P_HOST_IP=%%F
)

SetLocal EnableDelayedExpansion & REM All variables are set local to this run & expanded at execution time rather than at parse time (tip: echo !output!)

REM Complain if invalid arguments were provided.

if "%~1"=="" (
  goto printError
)
for %%a in (el-node cl-node validator docker-compose docker-compose-monitoring) do (
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


if "%~1"=="el-node" (

    if "%~2"=="init" (

        if exist .\root\chain\el (
          RD /S /Q .\root\chain\el
        )

        docker run -it ^
        -v %cd%\root:/root ^
        --name el-node --rm  ^
        bosagora/agora-el-node:agora_v1.12.0-66e599  ^
        --datadir=/root/chain/el  ^
        init /root/config/el/genesis.json

     ) else if "%~2"=="run" (

        docker run -it ^
        -v %cd%\root:/root ^
        -p 6060:6060 -p 8545:8545 -p 30303:30303 -p 30303:30303/udp ^
        --name el-node --rm  ^
        bosagora/agora-el-node:agora_v1.12.0-66e599  ^
        --config=/root/config/el/config.toml ^
        --datadir=/root/chain/el ^
        --syncmode=full --metrics --metrics.addr=0.0.0.0 --metrics.port=6060

     ) else if "%~2"=="run" (

        docker run -it ^
        -v %cd%\root:/root ^
        --name el-node-attach --rm ^
        bosagora/agora-el-node:agora_v1.12.0-66e599 ^
        --config=/root/config/el/config.toml ^
        --datadir=/root/chain/el ^
        attach /root/chain/el/geth.ipc

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
        -v %cd%\root\:/root ^
        -p 3500:3500 -p 4000:4000 -p 8080:8080 -p 13000:13000 -p 12000:12000/udp ^
        --name cl-node --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-node:agora_v4.0.5-ceb45d ^
        --chain-config-file=/root/config/cl/chain-config.yaml ^
        --config-file=/root/config/cl/config.yaml ^
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
            -v %cd%\root\:/root ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
            accounts import ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --keys-dir=/root/%~3 ^
            --wallet-dir=/root/wallet

        )

    ) else if "%~2"=="run" (

        docker run -it ^
          -v %cd%\root\:/root ^
          -p 8081:8081 ^
          --network="host" ^
          --name cl-validator --rm ^
          --platform linux/amd64 ^
          bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
          --chain-config-file=/root/config/cl/chain-config.yaml ^
          --config-file=/root/config/cl/config.yaml ^
          --datadir=/root/chain/cl/ ^
          --accept-terms-of-use ^
          --wallet-dir=/root/wallet ^
          --proposer-settings-file=/root/config/cl/proposer_config.json ^
          --wallet-password-file=/root/config/cl/password.txt ^
          --monitoring-port=8081

    ) else if "%~2"=="accounts" (

        if "%~3"=="import" (

            if "%~4"=="" (

                echo [31mUsage: ./agora.bat validator accounts import keys-dir.[0m
                echo [31mkeys-dir is the path to a directory where keystores to be imported are stored[0m
                exit /B 1

            ) else (

                docker run -it ^
                -v %cd%\root\:/root ^
                --name cl-validator --rm ^
                --platform linux/amd64 ^
                bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
                accounts import ^
                --accept-terms-of-use ^
                --chain-config-file=/root/config/cl/chain-config.yaml ^
                --keys-dir=/root/%~4 ^
                --wallet-dir=/root/wallet

            )

        ) else if "%~3"=="list" (

            docker run -it ^
            -v %cd%\root\:/root ^
            --network=host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
            accounts list ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --wallet-dir=/root/wallet

        ) else if "%~3"=="backup" (

            docker run -it ^
            -v %cd%\root\:/root ^
            --network=host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
            accounts backup ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --wallet-dir=/root/wallet ^
            --wallet-password-file=/root/config/cl/password.txt ^
            --backup-dir=/root/backup-wallet

        ) else (

            echo [31mFLAGS '%~3' is not found![0m
            echo [31mUsage: ./agora.bat validator accounts FLAGS.[0m
            echo [31mFLAGS can be import, list, voluntary-exit, backup [0m
            exit /B 1

        )

    ) else if "%~2"=="voluntary-exit" (

        docker run -it ^
        -v %cd%\root\:/root ^
        --net=bosagora_network ^
        --name cl-ctl --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-ctl:agora_v4.0.5-ceb45d ^
        validator exit ^
        --wallet-dir=/root/wallet ^
        --chain-config-file=/root/config/cl/chain-config.yaml ^
        --beacon-rpc-provider=node1-2-cl:4000 ^
        --accept-terms-of-use ^
        --wallet-password-file=/root/config/cl/password.txt

    ) else if "%~2"=="generate-bls-to-execution-change" (

        if "%~3"=="" (
            SET BLS2EXEC_DATA_FOLDER="bls_to_execution_changes"
        ) else (
            SET BLS2EXEC_DATA_FOLDER="%~3"
        )

        if exist .\root\%BLS2EXEC_DATA_FOLDER% (
          RD /S /Q .\root\%BLS2EXEC_DATA_FOLDER%
        )

        docker run -it ^
        -v %cd%\root\:/root ^
        --name deposit-ctl --rm ^
        bosagora/agora-deposit-cli:agora_v2.5.0-1839d2 ^
        --language=english ^
        generate-bls-to-execution-change ^
        --bls_to_execution_changes_folder=/root/%BLS2EXEC_DATA_FOLDER% ^
        --chain=devnet

    ) else if "%~2"=="withdraw" (

        if "%~3"=="" (
            SET BLS2EXEC_DATA_FOLDER="bls_to_execution_changes"
        ) else (
            SET BLS2EXEC_DATA_FOLDER="%~3"
        )

        docker run -it ^
        -v %cd%\root\:/root ^
        --net=bosagora_network ^
        --name cl-ctl --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-ctl:agora_v4.0.5-ceb45d ^
        validator withdraw ^
        --chain-config-file=/root/config/cl/chain-config.yaml ^
        --config-file=/root/config/cl/config.yaml ^
        --beacon-node-host=http://node1-2-cl:3500 ^
        --accept-terms-of-use ^
        --confirm ^
        --path=/root/%BLS2EXEC_DATA_FOLDER%

    ) else if "%~2"=="slashing-protection-history" (

        if "%~3"=="export" (

            docker run -it ^
            -v %cd%\root\:/root ^
            --network=host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
            slashing-protection-history export ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --datadir=/root/chain/cl/ ^
            --slashing-protection-export-dir=/root/slashing-protection-export

         ) else if "%~3"=="import" (

            docker run -it ^
            -v %cd%\root\:/root ^
            --network=host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
            slashing-protection-history import ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --datadir=/root/chain/cl/ ^
            --slashing-protection-json-file=/root/slashing-protection-export/slashing_protection.json

        ) else (

            echo [31mFLAGS '%~3' is not found![0m
            echo [31mUsage: ./agora.bat validator slashing-protection-history FLAGS.[0m
            echo [31mFLAGS can be import, export [0m
            exit /B 1

        )

    ) else if "%~2"=="wallet" (

        if "%~3"=="create" (

            docker run -it ^
            -v %cd%\root\:/root ^
            --network=host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d ^
            wallet create ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --wallet-dir=/root/wallet

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
