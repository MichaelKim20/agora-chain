# Agora Mainnet

- [Abort](#abort)

- [Install Docker Engine](#install-docker-engine)

- [For Linux or MacOS users](#for-linux-or-macos-users)
    - [Install](#install-for-linux-or-macos)
    - [Upgrade](#upgrade-for-linux-or-macos)
    - [Execution Layer](#execution-layer-for-linux-or-macos)
    - [Consensus Layer](#consensus-layer-for-linux-or-macos)
    - [Using docker-compose](#using-docker-compose-for-linux-or-macos)


- [For Windows users](#for-windows-users)
    - [Install](#install-for-windows)
    - [Upgrade](#upgrade-for-windows)
    - [Execution Layer](#execution-layer-for-windows)
    - [Consensus Layer](#consensus-layer-for-windows)
    - [Using docker-compose](#using-docker-compose-for-windows)


- [AWS 의 Ubuntu 에 BOSagora 노드 설치하기](docs/INSTALL-NODE-UBUNTU-KR.md)
- [NHN 클라우드의 Ubuntu 에 BOSagora 노드 설치하기](docs/INSTALL-NODE-UBUNTU-NHNCLOUD-KR.md)
- [Installing the BOSagora's node on Ubuntu on AWS](docs/INSTALL-NODE-UBUNTU-EN.md)

## Abort

[Agora-el](https://github.com/bosagora/agora-el) is an execution client that has an EVM.  
Agora-el was forked from Ethereum's execution client, [ethereum/go-ethereum](https://github.com/ethereum/go-ethereum)
version 1.10.23.  
We implemented the function of issuing commons budget in Agora-el.

[Agora-cl](https://github.com/bosagora/agora-cl) is a consensus client with a focus on usability, security, and
reliability.  
Agora-cl was forked from Ethereum's consensus client, [prysmaticlabs/prysm](https://github.com/prysmaticlabs/prysm)
version 3.1.1.  
We modified the block confirmation rewards in Agora-cl.

## Install Docker Engine

To run the Agora node, you must first install the Docker Engine.  
See [here](https://docs.docker.com/engine/install/) for instructions on how to install the Docker Engine  
https://docs.docker.com/engine/install/

## For Linux or MacOS users

### Install for Linux or MacOS

```shell
wget https://github.com/bosagora/agora-chain/archive/refs/heads/mainnet.zip -O mainnet.zip
unzip mainnet.zip
cd agora-chain-mainnet
```

### Upgrade for Linux or MacOS

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bosagora/agora-chain/devnet/upgrade.sh)"
```

### Execution Layer for Linux or MacOS

- Init execution node

  ```shell
  ./agora.sh el-node init
  ```

- Run execution node

  ```shell
  ./agora.sh el-node run
  ```

### Consensus Layer for Linux or MacOS

- Run consensus node

  ```shell
  ./agora.sh cl-node run
  ```

### Validator accounts for Linux or MacOS

- Import your key stores

  ```shell
  ./agora.sh validator import <your key stores folder>
  ```
  
  or

  ```shell
  ./agora.sh validator accounts import <your key stores folder>
  ```


- List your key stores in your wallet

  ```shell
  ./agora.sh validator accounts list
  ```


- Backup your key stores in your wallet

  ```shell
  ./agora.sh validator accounts backup <folder>
  ```
  `<folder>` is where the backup key is stored. The default folder is `./backup-wallet`

### Validator execution for Linux or MacOS

- Run validator

  ```shell
  ./agora.sh validator run
  ```

### Validator exit for Linux or MacOS

- Voluntary exit of the validator

  ```shell
  ./agora.sh validator exit
  ```

### Validator withdrawals for Linux or MacOS

- Generate the SignedBLSToExecutionChange data to enable withdrawals

  ```shell
  ./agora.sh validator generate-bls-to-execution-change <folder>
  ```
  `<folder>` is where the SignedBLSToExecutionChange data is stored. The default folder is `./bls_to_execution_changes`


- Send the SignedBLSToExecutionChange data to enable withdrawals

  ```shell
  ./agora.sh validator withdraw <folder>
  ```
  `<folder>` is where the SignedBLSToExecutionChange data is stored. The default folder is `./bls_to_execution_changes`


### Validator export & import slashing protection history for Linux or MacOS

- export

  ```shell
  ./agora.sh validator slashing-protection-history export <folder>
  ```
  `<folder>` is where the slashing protection history data is stored. The default folder is `./slashing-protection-export`


- import

  ```shell
  ./agora.sh validator slashing-protection-history import <folder>
  ```
  `<folder>` is where the slashing protection history data is stored. The default folder is `./slashing-protection-export`


### Using docker-compose for Linux or MacOS

1. Init the execution node

```shell
./agora.sh el-node init
```

2. Import your key stores

```shell
./agora.sh validator import <your key stores folder>
```

or

```shell
./agora.sh validator accounts import <your key stores folder>
```

3. Edit wallet password

```shell
nano ./root/config/cl/password.txt
```

4. Edit transaction fee receiving address

```shell
nano ./root/config/cl/proposer_config.json
```

5. Run docker-compose

```shell
./agora.sh docker-compose up
```

6. Stop docker-compose

```shell
./agora.sh docker-compose down
```

### Using docker-compose with monitoring for Linux or MacOS

1. Init the execution node

```shell
./agora.sh el-node init
```

2. Import your key stores

```shell
./agora.sh validator import <your key stores folder>
```

or

```shell
./agora.sh validator accounts import <your key stores folder>
```

3. Edit wallet password

```shell
nano ./root/config/cl/password.txt
```

4. Edit transaction fee receiving address

```shell
nano ./root/config/cl/proposer_config.json
```

5. Run docker-compose

```shell
./agora.sh docker-compose-monitoring up
```

6. Stop docker-compose

```shell
./agora.sh docker-compose-monitoring down
```

## For Windows users

### Install for Windows

```shell
curl -f -s -S -L -o devnet.zip https://github.com/bosagora/agora-chain/archive/refs/heads/devnet.zip
tar -xf devnet.zip
cd agora-chain-devnet
```

### Upgrade for Windows

```shell
curl -f -s -S -L -o upgrade.bat https://raw.githubusercontent.com/bosagora/agora-chain/devnet/upgrade.bat
upgrade.bat
```

### Execution Layer for Windows

- Init execution node

  ```shell
  agora.bat el-node init
  ```

- Run execution node
  
  ```shell
  agora.bat el-node run
  ```

### Consensus Layer for Windows

- Run consensus node
  
  ```shell
  agora.bat cl-node run
  ```

### Validator for Windows

- Import your key stores
  
  ```shell
  agora.bat validator import <your key stores folder>
  ```
  
  or
  
  ```shell
  agora.bat validator accounts import <your key stores folder>
  ```


- List your key stores in your wallet
  
  ```shell
  agora.bat validator accounts list
  ```


- Backup your key stores in your wallet

  ```shell
  agora.bat validator accounts backup <folder>
  ```
  `<folder>` is where the backup key is stored. The default folder is `./backup-wallet`

### Validator execution for Windows

- Run validator
  
  ```shell
  agora.bat validator run
  ```

### Validator exit for Windows

- Voluntary exit of the validator
  
  ```shell
  agora.bat validator exit
  ```

### Validator withdrawals for Windows

- Generate the SignedBLSToExecutionChange data to enable withdrawals

  ```shell
  agora.bat validator generate-bls-to-execution-change <folder>
  ```
  `<folder>` is where the SignedBLSToExecutionChange data is stored. The default folder is `./bls_to_execution_changes`


- Send the SignedBLSToExecutionChange data to enable withdrawals

  ```shell
  agora.bat validator withdraw <folder>
  ```
  `<folder>` is where the SignedBLSToExecutionChange data is stored. The default folder is `./bls_to_execution_changes`
  

### Validator export & import slashing protection history for Windows

- export

  ```shell
  ./agora.bat validator slashing-protection-history export <folder>
  ```
  `<folder>` is where the slashing protection history data is stored. The default folder is `./slashing-protection-export`


- import

  ```shell
  ./agora.bat validator slashing-protection-history import <folder>
  ```
  `<folder>` is where the slashing protection history data is stored. The default folder is `./slashing-protection-export`


### Using docker-compose for Windows

1. Init the execution node

```shell
agora.bat el-node init
```

2. Import your key stores

```shell
agora.bat validator import <your key stores folder>
```

or

```shell
agora.bat validator accounts import <your key stores folder>
```

3. Edit wallet password

```shell
notepad ./root/config/cl/password.txt
```

4. Edit transaction fee receiving address

```shell
notepad ./root/config/cl/proposer_config.json
```

5. Run docker-compose

```shell
agora.bat docker-compose up
```

6. Stop docker-compose

```shell
agora.bat docker-compose down
```

### Using docker-compose with monitoring for Windows

1. Init the execution node

```shell
agora.bat el-node init
```

2. Import your key stores

```shell
agora.bat validator import <your key stores folder>
```

or

```shell
agora.bat validator accounts import <your key stores folder>
```

3. Edit wallet password

```shell
notepad ./root/config/cl/password.txt
```

4. Edit transaction fee receiving address

```shell
notepad ./root/config/cl/proposer_config.json
```

5. Run docker-compose

```shell
agora.bat docker-compose-monitoring up
```

6. Stop docker-compose

```shell
agora.bat docker-compose-monitoring down
```

## Additional Information

[AWS 의 Ubuntu 에 BOSagora 노드 설치하기](docs/INSTALL-NODE-UBUNTU-KR.md)  
[Installing the BOSagora's node on Ubuntu on AWS](docs/INSTALL-NODE-UBUNTU-EN.md)
