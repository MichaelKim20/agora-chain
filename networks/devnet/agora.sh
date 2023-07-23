#!/bin/bash

set -eu

function color() {
    # Usage: color "31;5" "string"
    # Some valid values for color:
    # - 5 blink, 1 strong, 4 underlined
    # - fg: 31 red,  32 green, 33 yellow, 34 blue, 35 purple, 36 cyan, 37 white
    # - bg: 40 black, 41 red, 44 blue, 45 purple
    printf '\033[%sm%s\033[0m\n' "$@"
}

if [ "$#" -lt 1 ]; then
    color "31" "Usage: ./agora.sh PROCESS FLAGS."
    color "31" "PROCESS can be el-node, cl-node, validator, docker-compose, docker-compose-monitoring, start, stop, exec"
    exit 1
fi

system=""
case "$OSTYPE" in
darwin*) system="darwin" ;;
linux*) system="linux" ;;
msys*) system="windows" ;;
cygwin*) system="windows" ;;
*) exit 1 ;;
esac
readonly system

if [ "$1" = "el-node" ]; then
    if [ "$#" -lt 2 ]; then
        color "31" "Usage: ./agora.sh el-node FLAGS."
        color "31" "FLAGS can be init, run"
        exit 1
    fi

    if [ "$2" = "init" ]; then

        if [ "$system" == "linux" ]; then
            sudo rm -rf ./root/chain/el
        else
            rm -rf ./root/chain/el
        fi

        docker run -it \
        -v "$(pwd)"/root:/root \
        --name el-node --rm \
        bosagora/agora-el-node:v2.0.0 \
        --datadir=/root/chain/el \
        init \
        /root/config/el/genesis.json

    elif [ "$2" = "run" ]; then

        docker run -it \
        -v "$(pwd)"/root:/root \
        -p 6060:6060 -p 8545:8545 -p 30303:30303 -p 30303:30303/udp \
        --network bosagora_network \
        --name el-node --rm \
        bosagora/agora-el-node:v2.0.0 \
        --config=/root/config/el/config.toml \
        --datadir=/root/chain/el \
        --syncmode=full --metrics --metrics.addr=0.0.0.0 --metrics.port=6060

    elif [ "$2" = "attach" ]; then

        docker run -it \
        -v "$(pwd)"/root:/root \
        --network bosagora_network \
        --name el-node-attach --rm \
        bosagora/agora-el-node:v2.0.0 \
        --config=/root/config/el/config.toml \
        --datadir=/root/chain/el \
        attach /root/chain/el/geth.ipc

    else

        color "31" "FLAGS '$2' is not found!"
        color "31" "Usage: ./agora.sh el-node FLAGS."
        color "31" "FLAGS can be init, run, attach"
        exit 1

    fi

elif [ "$1" = "cl-node" ]; then

    if [ "$#" -lt 2 ]; then
        color "31" "Usage: ./agora.sh cl-node FLAGS."
        color "31" "FLAGS can be run"
        exit 1
    fi

    if [ "$2" = "run" ]; then

        docker run -it \
        -v "$(pwd)"/root:/root \
        -p 3500:3500 -p 4000:4000 -p 8080:8080 -p 13000:13000 -p 12000:12000/udp \
        --network bosagora_network \
        --name cl-node --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-node:agora_v4.0.5-32c8fd \
        --chain-config-file=/root/config/cl/chain-config.yaml \
        --config-file=/root/config/cl/config.yaml \
        --p2p-host-ip="$(curl -s https://ifconfig.me/ip)" \
        --monitoring-port=8080 \
        --checkpoint-sync-url=http://node1-2-cl:3500 \
        --genesis-beacon-api-url=http://node1-2-cl:3500

    elif [ "$2" = "clear-db" ]; then

        if [ "$system" == "linux" ]; then
            sudo rm -rf ./root/chain/cl/beaconchaindata
            sudo rm ./root/chain/cl/metaData
        else
            rm -rf ./root/chain/cl/beaconchaindata
            rm ./root/chain/cl/metaData
        fi

    else

        color "31" "FLAGS '$2' is not found!"
        color "31" "Usage: ./agora.sh cl-node FLAGS."
        color "31" "FLAGS can be run"
        exit 1

    fi

elif [ "$1" = "validator" ]; then

    if [ "$#" -lt 2 ]; then

        color "31" "Usage: ./agora.sh validator FLAGS."
        color "31" "FLAGS can be run, import, accounts, wallet"
        exit 1

    fi

    if [ "$2" = "import" ]; then

        if [ "$#" -lt 3 ]; then
            DATA_FOLDER="validator_keys"
            echo "Default keys folder is $DATA_FOLDER"
        else
            DATA_FOLDER="$3"
            echo "Keys folder is $DATA_FOLDER"
        fi

        docker run -it \
        -v "$(pwd)"/root:/root \
        -v "$(pwd)"/../../:/agora-chain \
        --name cl-validator --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-validator:agora_v4.0.5-32c8fd \
        accounts import \
        --chain-config-file=/root/config/cl/chain-config.yaml \
        --keys-dir=/agora-chain/"$DATA_FOLDER" \
        --wallet-dir=/root/wallet

    elif [ "$2" = "run" ]; then

        docker run -it \
        -v "$(pwd)"/root:/root \
        -p 8081:8081 \
        --network host \
        --name cl-validator --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-validator:agora_v4.0.5-32c8fd \
        --chain-config-file=/root/config/cl/chain-config.yaml \
        --config-file=/root/config/cl/config.yaml \
        --datadir=/root/chain/cl/ \
        --accept-terms-of-use \
        --wallet-dir=/root/wallet \
        --proposer-settings-file=/root/config/cl/proposer_config.json \
        --wallet-password-file=/root/config/cl/password.txt \
        --monitoring-port=8081

    elif [ "$2" = "accounts" ]; then

        if [ "$#" -lt 3 ]; then

            color "31" "Usage: ./agora.sh validator accounts FLAGS."
            color "31" "FLAGS can be import, list, voluntary-exit"
            exit 1

        fi

        if [ "$3" = "import" ]; then

            if [ "$#" -lt 4 ]; then
                DATA_FOLDER="validator_keys"
                echo "Default keys folder is $DATA_FOLDER"
            else
                DATA_FOLDER="$4"
                echo "Keys folder is $DATA_FOLDER"
            fi

            docker run -it \
            -v "$(pwd)"/root:/root \
            -v "$(pwd)"/../../:/agora-chain \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd \
            accounts import \
            --accept-terms-of-use \
            --chain-config-file=/root/config/cl/chain-config.yaml \
            --keys-dir=/agora-chain/"$DATA_FOLDER" \
            --wallet-dir=/root/wallet

        elif [ "$3" = "list" ]; then

            docker run -it \
            -v "$(pwd)"/root:/root \
            --network host \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd \
            accounts list \
            --accept-terms-of-use \
            --chain-config-file=/root/config/cl/chain-config.yaml \
            --wallet-dir=/root/wallet

        elif [ "$3" = "delete" ]; then

            docker run -it \
            -v "$(pwd)"/root:/root \
            -v "$(pwd)"/../../:/agora-chain \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd \
            accounts delete \
            --accept-terms-of-use \
            --chain-config-file=/root/config/cl/chain-config.yaml \
            --wallet-dir=/root/wallet

        elif [ "$3" = "backup" ]; then

            if [ "$#" -lt 4 ]; then
                DATA_FOLDER="backup-wallet"
                echo "Default backup folder is $DATA_FOLDER"
            else
                DATA_FOLDER="$4"
                echo "Backup folder is $DATA_FOLDER"
            fi

            if [ "$system" == "linux" ]; then
                sudo rm -rf "$(pwd)/../../$DATA_FOLDER"
            else
                rm -rf "$(pwd)/../../$DATA_FOLDER"
            fi

            docker run -it \
            -v "$(pwd)"/root:/root \
            -v "$(pwd)"/../../:/agora-chain \
            --network host \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd \
            accounts backup \
            --accept-terms-of-use \
            --chain-config-file=/root/config/cl/chain-config.yaml \
            --wallet-dir=/root/wallet \
            --wallet-password-file=/root/config/cl/password.txt \
            --backup-dir=/agora-chain/"$DATA_FOLDER"

            if [ "$system" == "linux" ]; then
                sudo chown -R "$USER" "$(pwd)/../../$DATA_FOLDER"
            else
                chown -R "$USER" "$(pwd)/../../$DATA_FOLDER"
            fi

        else

            color "31" "FLAGS '$3' is not found!"
            color "31" "Usage: ./agora.sh validator accounts FLAGS."
            color "31" "FLAGS can be import, list, backup"
            exit 1

        fi

    elif [ "$2" = "exit" ]; then

        docker run -it \
        -v "$(pwd)"/root:/root \
        --network bosagora_network \
        --name cl-ctl --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-ctl:agora_v4.0.5-32c8fd \
        validator exit \
        --wallet-dir=/root/wallet \
        --chain-config-file=/root/config/cl/chain-config.yaml \
        --beacon-rpc-provider=node1-2-cl:4000 \
        --accept-terms-of-use \
        --wallet-password-file=/root/config/cl/password.txt

    elif [ "$2" = "withdraw" ]; then

        if [ "$#" -lt 3 ]; then
            BLS2EXEC_DATA_FOLDER="bls_to_execution_changes"
            echo "Default data folder is $BLS2EXEC_DATA_FOLDER"
        else
            BLS2EXEC_DATA_FOLDER="$3"
            echo "Data folder is $BLS2EXEC_DATA_FOLDER"
        fi

        docker run -it \
        -v "$(pwd)"/root:/root \
        -v "$(pwd)"/../../:/agora-chain \
        --network bosagora_network \
        --name cl-ctl --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-ctl:agora_v4.0.5-32c8fd \
        validator withdraw \
        --chain-config-file=/root/config/cl/chain-config.yaml \
        --config-file=/root/config/cl/config.yaml \
        --beacon-node-host=http://node1-2-cl:3500 \
        --accept-terms-of-use \
        --confirm \
        --path=/agora-chain/"$BLS2EXEC_DATA_FOLDER"

    elif [ "$2" = "slashing-protection-history" ]; then

        if [ "$3" = "export" ]; then

            if [ "$#" -lt 4 ]; then
                DATA_FOLDER="slashing-protection-export"
                echo "Default slashing protection history folder is $DATA_FOLDER"
            else
                DATA_FOLDER="$4"
                echo "Slashing protection history folder is $DATA_FOLDER"
            fi

            if [ "$system" == "linux" ]; then
                sudo rm -rf "$(pwd)/../../$DATA_FOLDER"
            else
                rm -rf "$(pwd)/../../$DATA_FOLDER"
            fi

            docker run -it \
            -v "$(pwd)"/root:/root \
            -v "$(pwd)"/../../:/agora-chain \
            --network host \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd \
            slashing-protection-history export \
            --accept-terms-of-use \
            --chain-config-file=/root/config/cl/chain-config.yaml \
            --datadir=/root/chain/cl/ \
            --slashing-protection-export-dir=/agora-chain/"$DATA_FOLDER"

            if [ "$system" == "linux" ]; then
                sudo chown -R "$USER" "$(pwd)/../../$DATA_FOLDER"
            else
                chown -R "$USER" "$(pwd)/../../$DATA_FOLDER"
            fi

        elif [ "$3" = "import" ]; then

            if [ "$#" -lt 4 ]; then
                DATA_FOLDER="slashing-protection-export"
                echo "Default slashing protection history folder is $DATA_FOLDER"
            else
                DATA_FOLDER="$4"
                echo "Slashing protection history folder is $DATA_FOLDER"
            fi

            docker run -it \
            -v "$(pwd)"/root:/root \
            -v "$(pwd)"/../../:/agora-chain \
            --network host \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd \
            slashing-protection-history import \
            --accept-terms-of-use \
            --chain-config-file=/root/config/cl/chain-config.yaml \
            --datadir=/root/chain/cl/ \
            --slashing-protection-json-file=/agora-chain/"$DATA_FOLDER"/slashing_protection.json

        else

            color "31" "FLAGS '$3' is not found!"
            color "31" "Usage: ./agora.sh validator slashing-protection-history FLAGS."
            color "31" "FLAGS can be import, export"
            exit 1

        fi

    elif [ "$2" = "wallet" ]; then

        if [ "$#" -lt 3 ]; then

            color "31" "Usage: ./agora.sh validator wallet FLAGS."
            color "31" "FLAGS can be create"
            exit 1

        fi

        if [ "$3" = "create" ]; then

            if [ "$#" -lt 4 ]; then
                WALLET_FOLDER="wallet"
                echo "Wallet folder is $WALLET_FOLDER"
            else
                WALLET_FOLDER="$4"
                echo "Wallet folder is $WALLET_FOLDER"
            fi

            docker run -it \
            -v "$(pwd)"/root:/root \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd \
            wallet create \
            --accept-terms-of-use \
            --chain-config-file=/root/config/cl/chain-config.yaml \
            --wallet-dir=/root/$WALLET_FOLDER

        elif [ "$3" = "recover" ]; then

            if [ "$#" -lt 4 ]; then
                WALLET_FOLDER="recover"
                echo "Wallet folder is $WALLET_FOLDER"
            else
                WALLET_FOLDER="$4"
                echo "Wallet folder is $WALLET_FOLDER"
            fi

            docker run -it \
            -v "$(pwd)"/root:/root \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-32c8fd \
            wallet recover \
            --accept-terms-of-use \
            --chain-config-file=/root/config/cl/chain-config.yaml \
            --wallet-dir=/root/$WALLET_FOLDER

        else

            color "31" "FLAGS '$3' is not found!"
            color "31" "Usage: ./agora.sh validator wallet FLAGS."
            color "31" "FLAGS can be create, recover"
            exit 1

        fi

    else

        color "31" "FLAGS '$2' is not found!"
        color "31" "Usage: ./agora.sh validator FLAGS."
        color "31" "FLAGS can be run, import, accounts exit, withdraw, slashing-protection-history, wallet"
        exit 1

    fi

elif [ "$1" = "deposit-cli" ]; then

    if [ "$#" -lt 2 ]; then
        color "31" "Usage: ./agora.sh deposit-cli FLAGS."
        color "31" "FLAGS can be new-mnemonic, existing-mnemonic, generate-bls-to-execution-change"
        exit 1
    fi

    if [ "$2" = "new-mnemonic" ]; then

        docker run -it \
        -v "$(pwd)"/root:/root \
        -v "$(pwd)"/../../:/agora-chain \
        --name deposit-cli --rm \
        bosagora/agora-deposit-cli:agora_v2.5.0-f0d7d3 \
        --language=english \
        new-mnemonic \
        --folder=/agora-chain

    elif [ "$2" = "existing-mnemonic" ]; then

        docker run -it \
        -v "$(pwd)"/root:/root \
        -v "$(pwd)"/../../:/agora-chain \
        --name deposit-cli --rm \
        bosagora/agora-deposit-cli:agora_v2.5.0-f0d7d3 \
        --language=english \
        existing-mnemonic \
        --folder=/agora-chain

    elif [ "$2" = "generate-bls-to-execution-change" ]; then

        if [ "$#" -lt 3 ]; then
            BLS2EXEC_DATA_FOLDER="bls_to_execution_changes"
            echo "Default data folder is $BLS2EXEC_DATA_FOLDER"
        else
            BLS2EXEC_DATA_FOLDER="$3"
            echo "Data folder is $BLS2EXEC_DATA_FOLDER"
        fi

        if [ "$system" == "linux" ]; then
            sudo rm -rf "$(pwd)/../../$BLS2EXEC_DATA_FOLDER"
        else
            rm -rf "$(pwd)/../../$BLS2EXEC_DATA_FOLDER"
        fi

        mkdir -p "$(pwd)/../../$BLS2EXEC_DATA_FOLDER"

        docker run -it \
        -v "$(pwd)"/root:/root \
        -v "$(pwd)"/../../:/agora-chain \
        --name deposit-cli --rm \
        bosagora/agora-deposit-cli:agora_v2.5.0-f0d7d3 \
        --language=english \
        generate-bls-to-execution-change \
        --bls_to_execution_changes_folder=/agora-chain/"$BLS2EXEC_DATA_FOLDER"

        if [ "$system" == "linux" ]; then
            sudo chown -R "$USER" "$(pwd)/../../$BLS2EXEC_DATA_FOLDER"
        else
            chown -R "$USER" "$(pwd)/../../$BLS2EXEC_DATA_FOLDER"
        fi

    else

        color "31" "FLAGS '$2' is not found!"
        color "31" "Usage: ./agora.sh deposit-cli FLAGS."
        color "31" "FLAGS can be new-mnemonic, existing-mnemonic, generate-bls-to-execution-change"
        exit 1

    fi

elif [ "$1" = "docker-compose" ]; then

    if [ "$#" -lt 2 ]; then

        color "31" "Usage: ./agora.sh docker-compose FLAGS."
        color "31" "FLAGS can be up, down"
        exit 1

    fi

    P2P_HOST_IP=$(curl -s https://ifconfig.me/ip)
    rm -f "$(pwd)/.env" && echo "P2P_HOST_IP=$P2P_HOST_IP" >> "$(pwd)/.env"

    if [ "$2" = "up" ]; then

      docker-compose -f docker-compose.yml up -d

    elif [ "$2" = "down" ]; then

      docker-compose -f docker-compose.yml down

    else

        color "31" "FLAGS '$2' is not found!"
        color "31" "Usage: ./agora.sh docker-compose FLAGS."
        color "31" "FLAGS can be up, down"
        exit 1

    fi

elif [ "$1" = "docker-compose-monitoring" ]; then

    if [ "$#" -lt 2 ]; then

        color "31" "Usage: ./agora.sh docker-compose-monitoring FLAGS."
        color "31" "FLAGS can be up, down"
        exit 1

    fi

    P2P_HOST_IP=$(curl -s https://ifconfig.me/ip)
    rm -f "$(pwd)/.env" && echo "P2P_HOST_IP=$P2P_HOST_IP" >> "$(pwd)/.env"

    if [ "$2" = "up" ]; then

      docker-compose -f docker-compose-monitoring.yml up -d

    elif [ "$2" = "down" ]; then

      docker-compose -f docker-compose-monitoring.yml down

    else

        color "31" "FLAGS '$2' is not found!"
        color "31" "Usage: ./agora.sh docker-compose-monitoring FLAGS."
        color "31" "FLAGS can be up, down"
        exit 1

    fi

elif [ "$1" = "start" ]; then

    P2P_HOST_IP=$(curl -s https://ifconfig.me/ip)
    rm -f "$(pwd)/.env" && echo "P2P_HOST_IP=$P2P_HOST_IP" >> "$(pwd)/.env"
    docker-compose -f docker-compose-monitoring.yml up -d

elif [ "$1" = "stop" ]; then

    P2P_HOST_IP=$(curl -s https://ifconfig.me/ip)
    rm -f "$(pwd)/.env" && echo "P2P_HOST_IP=$P2P_HOST_IP" >> "$(pwd)/.env"
    docker-compose -f docker-compose-monitoring.yml down

elif [ "$1" = "exec" ]; then

    if [ "$#" -lt 2 ]; then
        color "31" "Usage: ./agora.sh exec FLAGS."
        color "31" "FLAGS can be el-node, cl-node, cl-validator, cl-ctl"
        exit 1
    fi

    echo 1. Folder Mount.
    echo This folder A [ "$(pwd)" ] is mounted as /root.
    echo Please use /root for the contents under folder A.
    echo 2. Folder Mount.
    echo This folder B [ "$(pwd)/../../" ]  is mounted as /agora-chain.
    echo Please use /agora-chain for the contents under folder B.

    if [ "$2" = "el-node" ]; then

        shift 2
        docker run -it \
        -v "$(pwd)"/root:/root \
        -v "$(pwd)"/../../:/agora-chain \
        --network bosagora_network \
        --name el-node-exec --rm \
        bosagora/agora-el-node:v2.0.0 \
        --datadir=/root/chain/el \
        --config=/root/config/el/config.toml \
        "$@"

    elif [ "$2" = "cl-node" ]; then

        shift 2
        docker run -it \
        -v "$(pwd)"/root:/root \
        -v "$(pwd)"/../../:/agora-chain \
        --network bosagora_network \
        --name cl-node-exec --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-node:agora_v4.0.5-32c8fd \
        "$@" \
        --accept-terms-of-use \
        --chain-config-file=/root/config/cl/chain-config.yaml \
        --config-file=/root/config/cl/config.yaml

    elif [ "$2" = "cl-validator" ]; then

        shift 2
        docker run -it \
        -v "$(pwd)"/root:/root \
        -v "$(pwd)"/../../:/agora-chain \
        --network bosagora_network \
        --name cl-validator-exec --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-validator:agora_v4.0.5-32c8fd \
        "$@" \
        --accept-terms-of-use \
        --chain-config-file=/root/config/cl/chain-config.yaml

    elif [ "$2" = "cl-ctl" ]; then

        shift 2
        docker run -it \
        -v "$(pwd)"/root:/root \
        -v "$(pwd)"/../../:/agora-chain \
        --network bosagora_network \
        --name cl-ctl-exec --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-ctl:agora_v4.0.5-32c8fd \
        "$@" \
        --accept-terms-of-use \
        --chain-config-file=/root/config/cl/chain-config.yaml

    else

        color "31" "FLAGS '$2' is not found!"
        color "31" "Usage: ./agora.sh exec FLAGS."
        color "31" "FLAGS can be el-node, cl-node, cl-validator, cl-ctl"
        exit 1

    fi

else

    color "31" "Process '$1' is not found!"
    color "31" "Usage: ./agora.sh PROCESS FLAGS."
    color "31" "PROCESS can be el-node, cl-node, validator, docker-compose, docker-compose-monitoring"
    exit 1

fi
