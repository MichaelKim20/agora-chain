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
    color "31" "PROCESS can be el-node, cl-node, validator, docker-compose"
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
        -v $(pwd)/root:/root \
        --name el-node --rm \
        bosagora/agora-el-node:v1.0.1 \
        --datadir=/root/chain/el \
        init \
        /root/config/el/genesis.json

    elif [ "$2" = "run" ]; then

        docker run -it \
        -v $(pwd)/root:/root \
        -p 6060:6060 -p 8545:8545 -p 30303:30303 -p 30303:30303/udp \
        --name el-node --rm \
        bosagora/agora-el-node:v1.0.1 \
        --config=/root/config/el/config.toml \
        --datadir=/root/chain/el \
        --syncmode=full --metrics --metrics.addr=0.0.0.0 --metrics.port=6060

    else

        color "31" "FLAGS '$2' is not found!"
        color "31" "Usage: ./agora.sh el-node FLAGS."
        color "31" "FLAGS can be init, run"
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
        -v $(pwd)/root/:/root \
        -p 3500:3500 -p 4000:4000 -p 8080:8080 -p 13000:13000 -p 12000:12000/udp \
        --name cl-node --rm \
        bosagora/agora-cl-node:v1.0.3 \
        --chain-config-file=/root/config/cl/chain-config.yaml \
        --config-file=/root/config/cl/config.yaml \
        --p2p-host-ip=$(curl -s https://ifconfig.me/ip) \
        --monitoring-port=8080

    else

        color "31" "FLAGS '$2' is not found!"
        color "31" "Usage: ./agora.sh cl-node FLAGS."
        color "31" "FLAGS can be run"
        exit 1

    fi

elif [ "$1" = "validator" ]; then

    if [ "$#" -lt 2 ]; then

        color "31" "Usage: ./agora.sh validator FLAGS."
        color "31" "FLAGS can be import, run"
        exit 1

    fi

    if [ "$2" = "import" ]; then

        if [ "$#" -lt 3 ]; then

            color "31" "Usage: ./agora.sh validator import keys-dir."
            color "31" "keys-dir is the path to a directory where keystores to be imported are stored"
            exit 1

        fi

        docker run -it \
        -v $(pwd)/root/:/root \
        --name cl-validator --rm \
        bosagora/agora-cl-validator:v1.0.3 \
        accounts import \
        --chain-config-file=/root/config/cl/chain-config.yaml \
        --keys-dir=/root/$3 \
        --wallet-dir=/root/wallet

    elif [ "$2" = "voluntary-exit" ]; then

        docker run -it \
        -v $(pwd)/root/:/root \
        --network=host \
        --name cl-validator --rm \
        bosagora/agora-cl-validator:v1.0.3 \
        accounts voluntary-exit \
        --chain-config-file=/root/config/cl/chain-config.yaml \
        --wallet-dir=/root/wallet \
        --beacon-rpc-provider=127.0.0.1:4000

    elif [ "$2" = "run" ]; then

        docker run -it \
        -v $(pwd)/root/:/root \
        -p 8081:8081 \
        --network="host" \
        --name cl-validator --rm \
        bosagora/agora-cl-validator:v1.0.3 \
        --chain-config-file=/root/config/cl/chain-config.yaml \
        --config-file=/root/config/cl/config.yaml \
        --datadir=/root/chain/cl/ \
        --wallet-dir=/root/wallet \
        --proposer-settings-file=/root/config/cl/proposer_config.json \
        --wallet-password-file=/root/config/cl/password.txt \
        --monitoring-port=8081

    else

        color "31" "FLAGS '$2' is not found!"
        color "31" "Usage: ./agora.sh validator FLAGS."
        color "31" "FLAGS can be import, voluntary-exit, run"
        exit 1

    fi
elif [ "$1" = "docker-compose" ]; then

    if [ "$#" -lt 2 ]; then

        color "31" "Usage: ./agora.sh docker-compose FLAGS."
        color "31" "FLAGS can be import, run"
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

else

    color "31" "Process '$1' is not found!"
    color "31" "Usage: ./agora.sh PROCESS FLAGS."
    color "31" "PROCESS can be el-node, cl-node, validator, docker-compose"
    exit 1

fi
