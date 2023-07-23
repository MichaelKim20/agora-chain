@ECHO OFF
FOR /F "tokens=* USEBACKQ" %%F IN (`curl -s https://ifconfig.me/ip`) DO (
    SET P2P_HOST_IP=%%F
)
echo P2P_HOST_IP=%P2P_HOST_IP%>.env

if "%~1"=="" (
  goto printError
)
for %%a in (el-node cl-node validator deposit-cli docker-compose docker-compose-monitoring start stop exec) do (
    if %1 equ %%a (
        goto validprocess
    )
)
:printError
echo [31mERROR: PROCESS missing or invalid[0m
echo Usage: agora.bat PROCESS FLAGS.
echo.
echo PROCESS can be el-node, cl-node, validator, docker-compose, docker-compose-monitoring, start, stop, exec.
echo FLAGS are the flags or arguments passed to the PROCESS.
echo.
exit /B 0
:validprocess

SetLocal EnableDelayedExpansion

if "%~1"=="el-node" (

    if "%~2"=="init" (

        if exist .\root\chain\el (
          RD /S /Q .\root\chain\el
        )

        docker run -it ^
        -v %cd%\root:/root ^
        --name el-node --rm  ^
        bosagora/agora-el-node:v2.0.0  ^
        --datadir=/root/chain/el  ^
        init /root/config/el/genesis.json

     ) else if "%~2"=="run" (

        docker run -it ^
        -v %cd%\root:/root ^
        -p 6060:6060 -p 8545:8545 -p 30303:30303 -p 30303:30303/udp ^
        --network bosagora_network ^
        --name el-node --rm  ^
        bosagora/agora-el-node:v2.0.0  ^
        --config=/root/config/el/config.toml ^
        --datadir=/root/chain/el ^
        --syncmode=full --metrics --metrics.addr=0.0.0.0 --metrics.port=6060

     ) else if "%~2"=="attach" (

        docker run -it ^
        -v %cd%\root:/root ^
        --network bosagora_network ^
        --name el-node-attach --rm ^
        bosagora/agora-el-node:v2.0.0 ^
        --config=/root/config/el/config.toml ^
        --datadir=/root/chain/el ^
        attach /root/chain/el/geth.ipc

    ) else (

        echo FLAGS are the flags or arguments passed to the PROCESS.
        echo [31mFLAGS '%~2' is not found![0m
        echo [31mUsage: agora.bat el-node FLAGS.[0m
        echo [31mFLAGS can be init, run[0m

    )

) else if "%~1"=="cl-node" (

    if "%~2"=="run" (

        docker run -it ^
        -v %cd%\root:/root ^
        -p 3500:3500 -p 4000:4000 -p 8080:8080 -p 13000:13000 -p 12000:12000/udp ^
        --network bosagora_network ^
        --name cl-node --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-node:agora_v4.0.5-32c8fd ^
        --chain-config-file=/root/config/cl/chain-config.yaml ^
        --config-file=/root/config/cl/config.yaml ^
        --p2p-host-ip=%P2P_HOST_IP% ^
        --monitoring-port=8080 ^
        --checkpoint-sync-url=http://node1-2-cl:3500 ^
        --genesis-beacon-api-url=http://node1-2-cl:3500

    ) else if "%~2"=="clear-db" (

        if exist .\root\chain\cl\beaconchaindata (
          RD /S /Q .\root\chain\cl\beaconchaindata
        )

        if exist .\root\chain\cl\metaData (
          DEL .\root\chain\cl\metaData
        )

    ) else (

        echo [31mFLAGS '%~2' is not found![0m
        echo [31mUsage: agora.bat cl-node FLAGS.[0m
        echo [31mFLAGS can be run[0m

    )

) else if "%~1"=="validator" (

    if "%~2"=="import" (

        if "%~3"=="" (
            SET DATA_FOLDER=validator_keys
            ECHO Default keys folder is !DATA_FOLDER!
        ) else (
            SET DATA_FOLDER=%~3
            ECHO Keys folder is !DATA_FOLDER!
        )

        docker run -it ^
        -v %cd%\root:/root ^
        -v %cd%\..\..\:/agora-chain ^
        --name cl-validator --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-validator:agora_v4.0.5-32c8fd ^
        accounts import ^
        --chain-config-file=/root/config/cl/chain-config.yaml ^
        --keys-dir=/agora-chain/!DATA_FOLDER! ^
        --wallet-dir=/root/wallet

    ) else if "%~2"=="run" (

        docker run -it ^
          -v %cd%\root:/root ^
          -p 8081:8081 ^
          --network host ^
          --name cl-validator --rm ^
          --platform linux/amd64 ^
          bosagora/agora-cl-validator:agora_v4.0.5-32c8fd ^
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
                SET DATA_FOLDER=validator_keys
                ECHO Default keys folder is !DATA_FOLDER!
            ) else (
                SET DATA_FOLDER=%~4
                ECHO Keys folder is !DATA_FOLDER!
            )

            docker run -it ^
            -v %cd%\root:/root ^
            -v %cd%\..\..\:/agora-chain ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd ^
            accounts import ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --keys-dir=/agora-chain/!DATA_FOLDER! ^
            --wallet-dir=/root/wallet

        ) else if "%~3"=="list" (

            docker run -it ^
            -v %cd%\root:/root ^
            --network host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd ^
            accounts list ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --wallet-dir=/root/wallet

        ) else if "%~3"=="delete" (

            docker run -it ^
            -v %cd%\root:/root ^
            -v %cd%\..\..\:/agora-chain ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd ^
            accounts delete ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --wallet-dir=/root/wallet

        ) else if "%~3"=="backup" (

            if "%~4"=="" (
                SET DATA_FOLDER=backup-wallet
                ECHO Default backup folder is !DATA_FOLDER!
            ) else (
                SET DATA_FOLDER=%~4
                ECHO Backup folder is !DATA_FOLDER!
            )

            if exist %cd%\..\..\!DATA_FOLDER! (
              RD /S /Q %cd%\..\..\!DATA_FOLDER!
            )

            docker run -it ^
            -v %cd%\root:/root ^
            -v %cd%\..\..\:/agora-chain ^
            --network host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd ^
            accounts backup ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --wallet-dir=/root/wallet ^
            --wallet-password-file=/root/config/cl/password.txt ^
            --backup-dir=/agora-chain/!DATA_FOLDER!

        ) else (

            echo [31mFLAGS '%~3' is not found![0m
            echo [31mUsage: agora.bat validator accounts FLAGS.[0m
            echo [31mFLAGS can be import, list, backup [0m
        )

    ) else if "%~2"=="exit" (

        docker run -it ^
        -v %cd%\root:/root ^
        --network bosagora_network ^
        --name cl-ctl --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-ctl:agora_v4.0.5-32c8fd ^
        validator exit ^
        --wallet-dir=/root/wallet ^
        --chain-config-file=/root/config/cl/chain-config.yaml ^
        --beacon-rpc-provider=node1-2-cl:4000 ^
        --accept-terms-of-use ^
        --wallet-password-file=/root/config/cl/password.txt

    ) else if "%~2"=="withdraw" (

        if "%~3"=="" (
            SET BLS2EXEC_DATA_FOLDER=bls_to_execution_changes
            ECHO Default data folder is !BLS2EXEC_DATA_FOLDER!
        ) else (
            SET BLS2EXEC_DATA_FOLDER=%~3
            ECHO Data folder is !BLS2EXEC_DATA_FOLDER!
        )

        docker run -it ^
        -v %cd%\root:/root ^
        -v %cd%\..\..\:/agora-chain ^
        --network bosagora_network ^
        --name cl-ctl --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-ctl:agora_v4.0.5-32c8fd ^
        validator withdraw ^
        --chain-config-file=/root/config/cl/chain-config.yaml ^
        --config-file=/root/config/cl/config.yaml ^
        --beacon-node-host=http://node1-2-cl:3500 ^
        --accept-terms-of-use ^
        --confirm ^
        --path=/agora-chain/!BLS2EXEC_DATA_FOLDER!

    ) else if "%~2"=="slashing-protection-history" (

        if "%~3"=="export" (

            if "%~4"=="" (
                SET DATA_FOLDER=slashing-protection-export
                ECHO Default slashing protection history folder is !DATA_FOLDER!
            ) else (
                SET DATA_FOLDER=%~4
                ECHO Slashing protection history folder is !DATA_FOLDER!
            )

            if exist %cd%\..\..\!DATA_FOLDER! (
              RD /S /Q %cd%\..\..\!DATA_FOLDER!
            )

            docker run -it ^
            -v %cd%\root:/root ^
            -v %cd%\..\..\:/agora-chain ^
            --network host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd ^
            slashing-protection-history export ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --datadir=/root/chain/cl/ ^
            --slashing-protection-export-dir=/agora-chain/!DATA_FOLDER!

         ) else if "%~3"=="import" (

            if "%~4"=="" (
                SET DATA_FOLDER=slashing-protection-export
                ECHO Default slashing protection history folder is !DATA_FOLDER!
            ) else (
                SET DATA_FOLDER=%~4
                ECHO Slashing protection history folder is !DATA_FOLDER!
            )

            docker run -it ^
            -v %cd%\root:/root ^
            -v %cd%\..\..\:/agora-chain ^
            --network host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd ^
            slashing-protection-history import ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --datadir=/root/chain/cl/ ^
            --slashing-protection-json-file=/agora-chain/!DATA_FOLDER!/slashing_protection.json

        ) else (

            echo [31mFLAGS '%~3' is not found![0m
            echo [31mUsage: agora.bat validator slashing-protection-history FLAGS.[0m
            echo [31mFLAGS can be import, export [0m

        )

    ) else if "%~2"=="wallet" (

        if "%~3"=="create" (

            if "%~4"=="" (
                SET WALLET_FOLDER=wallet
                ECHO Wallet folder is !WALLET_FOLDER!
            ) else (
                SET WALLET_FOLDER=%~4
                ECHO Wallet folder is !WALLET_FOLDER!
            )

            docker run -it ^
            -v %cd%\root:/root ^
            --network host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd ^
            wallet create ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --wallet-dir=/root/!WALLET_FOLDER!

        ) else if "%~3"=="recover" (

            if "%~4"=="" (
                SET WALLET_FOLDER=recover
                ECHO Wallet folder is !WALLET_FOLDER!
            ) else (
                SET WALLET_FOLDER=%~4
                ECHO Wallet folder is !WALLET_FOLDER!
            )

            docker run -it ^
            -v %cd%\root:/root ^
            --network host ^
            --name cl-validator --rm ^
            --platform linux/amd64 ^
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd ^
            wallet recover ^
            --accept-terms-of-use ^
            --chain-config-file=/root/config/cl/chain-config.yaml ^
            --wallet-dir=/root/!WALLET_FOLDER!

        ) else (

            echo [31mFLAGS '%~3' is not found![0m
            echo [31mUsage: agora.bat validator wallet FLAGS.[0m
            echo [31mFLAGS can be create, recover[0m

        )

    ) else (

        echo [31mFLAGS '%~2' is not found![0m
        echo [31mUsage: agora.bat validator FLAGS.[0m
        echo [31mFLAGS can be run, accounts, wallet[0m

    )

) else if "%~1"=="deposit-cli" (

    if "%~2"=="new-mnemonic" (

        docker run -it ^
        -v %cd%\root:/root ^
        -v %cd%\..\..\:/agora-chain ^
        --name deposit-cli --rm ^
        bosagora/agora-deposit-cli:agora_v2.5.0-f0d7d3 ^
        --language=english ^
        new-mnemonic ^
        --folder=/agora-chain

    ) else if "%~2"=="existing-mnemonic" (

        docker run -it ^
        -v %cd%\root:/root ^
        -v %cd%\..\..\:/agora-chain ^
        --name deposit-cli --rm ^
        bosagora/agora-deposit-cli:agora_v2.5.0-f0d7d3 ^
        --language=english ^
        existing-mnemonic ^
        --folder=/agora-chain

    ) else if "%~2"=="generate-bls-to-execution-change" (

        if "%~3"=="" (
            SET BLS2EXEC_DATA_FOLDER=bls_to_execution_changes
            ECHO Default data folder is !BLS2EXEC_DATA_FOLDER!
        ) else (
            SET BLS2EXEC_DATA_FOLDER=%~3
            ECHO Data folder is !BLS2EXEC_DATA_FOLDER!
        )

        if exist %cd%\..\..\!BLS2EXEC_DATA_FOLDER! (
          RD /S /Q %cd%\..\..\!BLS2EXEC_DATA_FOLDER!
        )

        mkdir %cd%\..\..\!BLS2EXEC_DATA_FOLDER!

        docker run -it ^
        -v %cd%\root:/root ^
        -v %cd%\..\..\:/agora-chain ^
        --name deposit-ctl --rm ^
        bosagora/agora-deposit-cli:agora_v2.5.0-f0d7d3 ^
        --language=english ^
        generate-bls-to-execution-change ^
        --bls_to_execution_changes_folder=/agora-chain/!BLS2EXEC_DATA_FOLDER! ^
        --chain=devnet

    ) else (

        echo [31mFLAGS '%~2' is not found![0m
        echo [31mUsage: agora.bat deposit-cli FLAGS.[0m
        echo [31mFLAGS can be new-mnemonic, existing-mnemonic, generate-bls-to-execution-change[0m

    )

) else if "%~1"=="docker-compose" (

    if "%~2"=="up" (

        docker-compose -f docker-compose.yml up -d

    ) else if "%~2"=="down" (

        docker-compose -f docker-compose.yml down

    ) else (

        echo [31mFLAGS '%~2' is not found![0m
        echo [31mUsage: agora.bat docker-compose FLAGS.[0m
        echo [31mFLAGS can be up down[0m

    )

) else if "%~1"=="docker-compose-monitoring" (

    if "%~2"=="up" (

        docker-compose -f docker-compose-monitoring.yml up -d

    ) else if "%~2"=="down" (

        docker-compose -f docker-compose-monitoring.yml down

    ) else (

        echo [31mFLAGS '%~2' is not found![0m
        echo [31mUsage: agora.bat docker-compose-monitoring FLAGS.[0m
        echo [31mFLAGS can be up down[0m

    )

) else if "%~1"=="start" (

    docker-compose -f docker-compose-monitoring.yml up -d

) else if "%~1"=="stop" (

    docker-compose -f docker-compose-monitoring.yml down

) else if "%~1"=="exec" (

    echo 1. Folder Mount.
    echo This folder A [ %cd% ] is mounted as /root.
    echo Please use /root for the contents under folder A.
    echo 2. Folder Mount.
    echo This folder B [ %cd%\..\..\ ]  is mounted as /agora-chain.
    echo Please use /agora-chain for the contents under folder B.

    set /a argc=0
    set args=
    for %%x in (%*) do (
        set /a argc = argc+=1
        if !argc! gtr 2 (
            set args=!args! %%x
        )
    )

    if "%~2"=="el-node" (

        docker run -it ^
        -v %cd%\root:/root ^
        -v %cd%\..\..\:/agora-chain ^
        --network bosagora_network ^
        --name el-node --rm  ^
        bosagora/agora-el-node:v2.0.0  ^
        --config=/root/config/el/config.toml ^
        --datadir=/root/chain/el ^
        !args!

    ) else if "%~2"=="cl-node" (

        docker run -it ^
        -v %cd%\root:/root ^
        -v %cd%\..\..\:/agora-chain ^
        --network bosagora_network ^
        --name cl-node-exec --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-node:agora_v4.0.5-32c8fd ^
        !args! ^
        --accept-terms-of-use ^
        --chain-config-file=/root/config/cl/chain-config.yaml ^
        --config-file=/root/config/cl/config.yaml

    ) else if "%~2"=="cl-validator" (

        docker run -it ^
        -v %cd%\root:/root ^
        -v %cd%\..\..\:/agora-chain ^
        --network bosagora_network ^
        --name cl-validator-exec --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-validator:agora_v4.0.5-32c8fd ^
        !args! ^
        --accept-terms-of-use ^
        --chain-config-file=/root/config/cl/chain-config.yaml

    ) else if "%~2"=="cl-ctl" (

        docker run -it ^
        -v %cd%\root:/root ^
        -v %cd%\..\..\:/agora-chain ^
        --network bosagora_network ^
        --name cl-ctl-exec --rm ^
        --platform linux/amd64 ^
        bosagora/agora-cl-ctl:agora_v4.0.5-32c8fd ^
        !args! ^
        --accept-terms-of-use ^
        --chain-config-file=/root/config/cl/chain-config.yaml

    ) else (

        echo [31mFLAGS '%~2' is not found![0m
        echo [31mUsage: agora.bat exec FLAGS.[0m
        echo [31mFLAGS can be el-node, cl-node, cl-validator, cl-ctl[0m

    )

) else (

    echo [31mProcess '%~1' is not found![0m
    echo [31mUsage: agora.bat PROCESS FLAGS.[0m
    echo [31mPROCESS can be el-node, cl-node, validator, docker-compose, docker-compose-monitoring, start, stop, exec[0m

)

EndLocal
