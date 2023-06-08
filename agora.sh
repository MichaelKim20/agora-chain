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

function create_folder() {
    mkdir -p "$@"
}

function download_file() {
    wget https://raw.githubusercontent.com/bosagora/agora-chain/devnet/"$*" -q -O "$*"
}

if [ "$#" -lt 1 ]; then
    color "31" "Usage: ./agora.sh PROCESS FLAGS."
    color "31" "PROCESS can be el-node, cl-node, validator, upgrade, docker-compose, docker-compose-monitoring"
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

if [ ! -d "root" ]
then
    create_folder root
    create_folder root/config
    create_folder root/config/cl
    create_folder root/config/el
    download_file root/config/cl/chain-config.yaml
    download_file root/config/cl/config.yaml
    download_file root/config/el/config.toml
    download_file root/config/el/genesis.json
    download_file agora.bat
    download_file agora.sh
    download_file docker-compose.yml
    download_file docker-compose-monitoring.yml

    chmod 755 agora.sh
fi

if [ ! -d "monitoring" ]
then
    create_folder monitoring
    create_folder monitoring/dashboard
    create_folder monitoring/prometheus
    download_file monitoring/dashboard/agora-chain-dashboard.json
    download_file monitoring/prometheus/config.yml
fi




































if [ "$1" = "upgrade" ]; then

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bosagora/agora-chain/devnet/upgrade.sh)"

elif [ "$1" = "el-node" ]; then
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
        -v "$(pwd)":/agora-chain \
        --name el-node --rm \
        bosagora/agora-el-node:agora_v1.12.0-66e599 \
        --datadir=/agora-chain/root/chain/el \
        init \
        /agora-chain/root/config/el/genesis.json

    elif [ "$2" = "run" ]; then

        docker run -it \
        -v "$(pwd)":/agora-chain \
        -p 6060:6060 -p 8545:8545 -p 30303:30303 -p 30303:30303/udp \
        --net bosagora_network \
        --name el-node --rm \
        bosagora/agora-el-node:agora_v1.12.0-66e599 \
        --config=/agora-chain/root/config/el/config.toml \
        --datadir=/agora-chain/root/chain/el \
        --syncmode=full --metrics --metrics.addr=0.0.0.0 --metrics.port=6060

    elif [ "$2" = "attach" ]; then

        docker run -it \
        -v "$(pwd)":/agora-chain \
        --net bosagora_network \
        --name el-node-attach --rm \
        bosagora/agora-el-node:agora_v1.12.0-66e599 \
        --config=/agora-chain/root/config/el/config.toml \
        --datadir=/agora-chain/root/chain/el \
        attach /agora-chain/root/chain/el/geth.ipc

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
        -v "$(pwd)":/agora-chain \
        -p 3500:3500 -p 4000:4000 -p 8080:8080 -p 13000:13000 -p 12000:12000/udp \
        --net bosagora_network \
        --name cl-node --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-node:agora_v4.0.5-ceb45d \
        --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml \
        --config-file=/agora-chain/root/config/cl/config.yaml \
        --p2p-host-ip="$(curl -s https://ifconfig.me/ip)" \
        --monitoring-port=8080 \
        --checkpoint-sync-url=http://node1-2-cl:3500 \
        --genesis-beacon-api-url=http://node1-2-cl:3500

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

            color "31" "Usage: ./agora.sh validator import keys-dir."
            color "31" "keys-dir is the path to a directory where key stores to be imported are stored"
            exit 1

        fi

        docker run -it \
        -v "$(pwd)":/agora-chain \
        --name cl-validator --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-validator:agora_v4.0.5-ceb45d \
        accounts import \
        --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml \
        --keys-dir=/agora-chain/"$3" \
        --wallet-dir=/agora-chain/root/wallet

    elif [ "$2" = "run" ]; then

        docker run -it \
        -v "$(pwd)":/agora-chain \
        -p 8081:8081 \
        --network="host" \
        --name cl-validator --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-validator:agora_v4.0.5-ceb45d \
        --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml \
        --config-file=/agora-chain/root/config/cl/config.yaml \
        --datadir=/agora-chain/root/chain/cl/ \
        --accept-terms-of-use \
        --wallet-dir=/agora-chain/root/wallet \
        --proposer-settings-file=/agora-chain/root/config/cl/proposer_config.json \
        --wallet-password-file=/agora-chain/root/config/cl/password.txt \
        --monitoring-port=8081

    elif [ "$2" = "accounts" ]; then

        if [ "$#" -lt 3 ]; then

            color "31" "Usage: ./agora.sh validator accounts FLAGS."
            color "31" "FLAGS can be import, list, voluntary-exit"
            exit 1

        fi

        if [ "$3" = "import" ]; then

            if [ "$#" -lt 4 ]; then

                color "31" "Usage: ./agora.sh validator accounts import keys-dir."
                color "31" "keys-dir is the path to a directory where key stores to be imported are stored"
                exit 1

            fi

            docker run -it \
            -v "$(pwd)":/agora-chain \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d \
            accounts import \
            --accept-terms-of-use \
            --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml \
            --keys-dir=/agora-chain/"$4" \
            --wallet-dir=/agora-chain/root/wallet

        elif [ "$3" = "list" ]; then

            docker run -it \
            -v "$(pwd)":/agora-chain \
            --network=host \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d \
            accounts list \
            --accept-terms-of-use \
            --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml \
            --wallet-dir=/agora-chain/root/wallet

        elif [ "$3" = "backup" ]; then

            if [ "$#" -lt 4 ]; then
                DATA_FOLDER="backup-wallet"
                echo "Default backup folder is $DATA_FOLDER"
            else
                DATA_FOLDER="$4"
            fi

            if [ "$system" == "linux" ]; then
                sudo rm -rf "$DATA_FOLDER"
            else
                rm -rf "$DATA_FOLDER"
            fi

            docker run -it \
            -v "$(pwd)":/agora-chain \
            --network=host \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d \
            accounts backup \
            --accept-terms-of-use \
            --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml \
            --wallet-dir=/agora-chain/root/wallet \
            --wallet-password-file=/agora-chain/root/config/cl/password.txt \
            --backup-dir=/agora-chain/"$DATA_FOLDER"

            if [ "$system" == "linux" ]; then
                sudo chown -R "$USER" "$DATA_FOLDER"
            else
                chown -R "$USER" "$DATA_FOLDER"
            fi

        else

            color "31" "FLAGS '$3' is not found!"
            color "31" "Usage: ./agora.sh validator accounts FLAGS."
            color "31" "FLAGS can be import, list, backup"
            exit 1

        fi

    elif [ "$2" = "exit" ]; then

        docker run -it \
        -v "$(pwd)":/agora-chain \
        --net bosagora_network \
        --name cl-ctl --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-ctl:agora_v4.0.5-ceb45d \
        validator exit \
        --wallet-dir=/agora-chain/root/wallet \
        --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml \
        --beacon-rpc-provider=node1-2-cl:4000 \
        --accept-terms-of-use \
        --wallet-password-file=/agora-chain/root/config/cl/password.txt

    elif [ "$2" = "generate-bls-to-execution-change" ]; then

        if [ "$#" -lt 3 ]; then
            BLS2EXEC_DATA_FOLDER="bls_to_execution_changes"
            echo "Default data folder is $BLS2EXEC_DATA_FOLDER"
        else
            BLS2EXEC_DATA_FOLDER="$3"
        fi

        if [ "$system" == "linux" ]; then
            sudo rm -rf "$BLS2EXEC_DATA_FOLDER"
        else
            rm -rf "$BLS2EXEC_DATA_FOLDER"
        fi

        mkdir -p "$BLS2EXEC_DATA_FOLDER"

        docker run -it \
        -v "$(pwd)":/agora-chain \
        --name deposit-ctl --rm \
        bosagora/agora-deposit-cli:agora_v2.5.0-1839d2 \
        --language=english \
        generate-bls-to-execution-change \
        --bls_to_execution_changes_folder=/agora-chain/"$BLS2EXEC_DATA_FOLDER" \
        --chain=devnet

        if [ "$system" == "linux" ]; then
            sudo chown -R "$USER" "$BLS2EXEC_DATA_FOLDER"
        else
            chown -R "$USER" "$BLS2EXEC_DATA_FOLDER"
        fi

    elif [ "$2" = "withdraw" ]; then

        if [ "$#" -lt 3 ]; then
            BLS2EXEC_DATA_FOLDER="bls_to_execution_changes"
        else
            BLS2EXEC_DATA_FOLDER="$3"
        fi

        docker run -it \
        -v "$(pwd)":/agora-chain \
        --net bosagora_network \
        --name cl-ctl --rm \
        --platform linux/amd64 \
        bosagora/agora-cl-ctl:agora_v4.0.5-ceb45d \
        validator withdraw \
        --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml \
        --config-file=/agora-chain/root/config/cl/config.yaml \
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
            fi

            if [ "$system" == "linux" ]; then
                sudo rm -rf "$DATA_FOLDER"
            else
                rm -rf "$DATA_FOLDER"
            fi

            docker run -it \
            -v "$(pwd)":/agora-chain \
            --network=host \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d \
            slashing-protection-history export \
            --accept-terms-of-use \
            --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml \
            --datadir=/agora-chain/root/chain/cl/ \
            --slashing-protection-export-dir=/agora-chain/"$DATA_FOLDER"

            if [ "$system" == "linux" ]; then
                sudo chown -R "$USER" "$DATA_FOLDER"
            else
                chown -R "$USER" "$DATA_FOLDER"
            fi

        elif [ "$3" = "import" ]; then

            if [ "$#" -lt 4 ]; then
                DATA_FOLDER="slashing-protection-export"
                echo "Default slashing protection history folder is $DATA_FOLDER"
            else
                DATA_FOLDER="$4"
            fi

            docker run -it \
            -v "$(pwd)":/agora-chain \
            --network=host \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d \
            slashing-protection-history import \
            --accept-terms-of-use \
            --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml \
            --datadir=/agora-chain/root/chain/cl/ \
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

            docker run -it \
            -v "$(pwd)":/agora-chain \
            --name cl-validator --rm \
            --platform linux/amd64 \
            bosagora/agora-cl-validator:agora_v4.0.5-ceb45d \
            wallet create \
            --accept-terms-of-use \
            --chain-config-file=/agora-chain/root/config/cl/chain-config.yaml \
            --wallet-dir=/agora-chain/root/wallet

        else

            color "31" "FLAGS '$3' is not found!"
            color "31" "Usage: ./agora.sh validator wallet FLAGS."
            color "31" "FLAGS can be create"
            exit 1

        fi

    else

        color "31" "FLAGS '$2' is not found!"
        color "31" "Usage: ./agora.sh validator FLAGS."
        color "31" "FLAGS can be run, import, accounts exit, generate-bls-to-execution-change, withdraw, slashing-protection-history, wallet"
        exit 1

    fi

elif [ "$1" = "docker-compose" ]; then

    if [ "$#" -lt 2 ]; then

        color "31" "Usage: ./agora.sh docker-compose FLAGS."
        color "31" "FLAGS can be up, down"
        exit 1

    fi

    export P2P_HOST_IP=$(curl -s https://ifconfig.me/ip)

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

    export P2P_HOST_IP=$(curl -s https://ifconfig.me/ip)

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

else

    color "31" "Process '$1' is not found!"
    color "31" "Usage: ./agora.sh PROCESS FLAGS."
    color "31" "PROCESS can be el-node, cl-node, validator, upgrade, docker-compose, docker-compose-monitoring"
    exit 1

fi
