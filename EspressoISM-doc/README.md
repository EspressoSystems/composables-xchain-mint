Reference https://github.com/EspressoSystems/hyperlane-integration-poc

## Launch source and destination chains with predeployed hyperlane contracts.

Note: To process messages between chains anvil nodes should have automatic mine --block-time 5 set in the terminal (check launch_source_chain.sh and launch_destination_chain.sh scripts.).


Install the Hyperlane [CLI](https://docs.hyperlane.xyz/docs/reference/cli) using the following command:
`npm install -g @hyperlane-xyz/cli `

Run the following commands from the `anvil` directory unless otherwise stated.

Set Hyperlane environment variables
```
source .hyperlane_env
```

In a separate terminal, launch the source chain anvil node; note this script automatically sources the environment variables:
```
./anvil/launch_source_chain.sh

```
In a separate terminal, launch the destination chain anvil node:
```
./anvil/launch_destination_chain.sh

```


## Go down to the # `Run a validator and relayer.` and try to up and run validator and relayer. Then try to send test message by executing step `Send a test message between two chains` below. If hyperlane config errors apperas, then you have to setup hyperlane config and redeploy hyperlane contracts on both empty anvil chains from scratch. Execute instructions below and then try to send test message again:

First the source chain:
```bash
> hyperlane registry init

```bash
> hyperlane registry init
? Detected rpc url as http://localhost:8545 from JSON RPC provider, is this
correct? n
? Enter http or https rpc url: (http://localhost:8545) http://localhost:8547
? Enter chain name (one word, lower case) source
? Enter chain display name (Source) [PUSH ENTER]
? Detected chain id as 412346 from JSON RPC provider, is this correct? (Y/n) [PUSH ENTER]
? Is this chain a testnet (a chain used for testing & development)? (Y/n) [PUSH ENTER]
? Select the chain technical stack (Use arrow keys) arbitrumnitro
? Detected starting block number for indexing as 0 from JSON RPC provider, is
this correct? (Y/n) [PUSH ENTER]
? Do you want to add a block explorer config for this chain (y/N) [PUSH ENTER]
? Do you want to set block or gas properties for this chain config (y/N) [PUSH ENTER]
? Do you want to set native token properties for this chain config (defaults to
ETH) (y/N) [PUSH ENTER]
```


Then the destination chain:
```bash
> hyperlane registry init
? Detected rpc url as http://localhost:8545 from JSON RPC provider, is this
correct? n
? Enter http or https rpc url: (http://localhost:8545) http://localhost:8549
? Enter chain name (one word, lower case) destination
? Enter chain display name (Destination) [PUSH ENTER]
? Detected chain id as 31338 from JSON RPC provider, is this correct? (Y/n) [PUSH ENTER]
? Is this chain a testnet (a chain used for testing & development)? (Y/n) [PUSH ENTER]
? Select the chain technical stack (Use arrow keys) arbitrumnitro
? Detected starting block number for indexing as 30 from JSON RPC provider, is
this correct? (Y/n) [PUSH ENTER]
? Do you want to add a block explorer config for this chain (y/N) [PUSH ENTER]
? Do you want to set block or gas properties for this chain config (y/N) [PUSH ENTER]
? Do you want to set native token properties for this chain config (defaults to
ETH) (y/N) [PUSH ENTER]
```

Note that it is not necessary to initialize the configuration of the core contracts because it is already hardcoded in `.anvil/hyperlane/chains/source/core-config.yaml` and `.anvil/hyperlane/chains/destination/core-config.yaml`.
However, this file depends on the agents' addresses and thus needs to be generated with the following command:

```
> ./scripts/create-core-config.sh
```

Note that current configuration considers a default ISM using a multisig of a single signer with Interchain Gas Paymaster that allows to pays fees on destination chain. This configuration uses Aggregation hook that aggregate merkleTree and interchainGasPaymaster hooks. Hyperlane setup use messageIdMultisigIsm as default ISM that signs message id and it fits current needs. For the prod release we will use our own multisigISM with espresso TEE verify.

If you need to re-configure hyperlane core-config.yaml files, use command:
```bash
> hyperlane core init --advanced
```

Deploy the Hyperlane contracts on the source chain.
```bash
> hyperlane core deploy  --config ./anvil/hyperlane/chains/source/core-config.yaml
? Select network type (Use arrow keys) [PICK Testnet]
? Select chain to connect: [TYPE source]
? Do you want to use an API key to verify on this (source) chain's block
explorer (y/N) [PUSH ENTER]
? Is this deployment plan correct? (Y/n) [PUSH ENTER]
```

Deploy the Hyperlane contracts on the destination chain.
```bash
> hyperlane core deploy  --config ./anvil/hyperlane/chains/destination/core-config.yaml
? Select network type (Use arrow keys) [PICK Testnet]
? Select chain to connect: [TYPE destination]
? Do you want to use an API key to verify on this (destination) chain's block
explorer (y/N) [PUSH ENTER]
? Is this deployment plan correct? (Y/n) [PUSH ENTER]
```

# Run a validator and relayer.
1. Create and fill .env file according to the env.example.
2. Load env files by `export $(grep -v '^#' .env | xargs)`
3. Run `.anvil/hyperlane/validator-relayer-setup/scripts/update-agent-config.sh` to generate hyperlane agent.json config.
4. Run docker-compose up in the separate terminal.
5. Check validator logs  `docker logs -f source-validator`. Run in the separate terminal.
6. Check relayer logs  `docker logs -f relayer`. Run in the separate terminal.


# Send a test message between two chains
Send a test message from the source chain to the destination chain.
```bash
> hyperlane send message
  [ SELECT Testnet > source ]
  [ SELECT Testnet > destination ]
 ...
Waiting for message delivery on destination chain...
Message 0xe1df47d14d314ab2d616ebdb8b83f8e92d929ec84c509404d2586b63bafdedf9 was processed
All messages processed for tx 0x3151e1ec80e4aa0249c058508dfa5e83d84209e444bfd343f983f21eb6d0e996
Message was delivered!
```

### Deploy EspressoEscrow to source and destionation local chains
Open `contracts` folder
```bash
$ ./script/escrow/deploy-espresso-escrow-2-chain.sh
```

## Mint X chain NFT between on different chains

Check the nft ids count on NFT Contract before sending the message

```bash
> ../contracts/script/xchain-mint/get_nfts_count.sh
0x0000000000000000000000000000000000000000000000000000000000000000
```

```bash
> ../contracts/script/xchain-mint/xchain_mint.sh
```


Wait a few seconds and check the the nft ids count on the NFT contract again. Newly minted NFT should exist.

```bash
> ../contracts/script/xchain-mint/get_nfts_count.sh
0x0000000000000000000000000000000000000000000000000000000000000001
```


# Warp Route deploy and scripts

Generate warp route config:

```
> ./scripts/create-warp-route-config
```

Or you need to re-configure hyperlane warp route destination-deploy.yaml file, use command:
```bash
> hyperlane warp init --advanced  --registry hyperlane
```

Deploy warp route contracts:
```
> hyperlane warp deploy  --registry hyperlane
```

## Send tokens via hyperlane CLI

Send a test 1 wei tokens from source chain to the destination chain
```bash
> hyperlane warp send --symbol ETH --registry hyperlane
  [ SELECT Testnet > source ]
  [ SELECT Testnet > destination ]
å
Sending a message from source to destination
Pending 0x98f39774735d08de29fa005ce907d810e3afbd9c80a502f6ea15bf03b3c41a77 (waiting 1 blocks for confirmation)
Sent transfer from sender (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) on source to recipient (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) on destination.
Message ID: 0xf67b408b252e8955b82b5e264ba1753dc93c217dc782d146b4a34779324e2f73
Message 0xf67b408b252e8955b82b5e264ba1753dc93c217dc782d146b4a34779324e2f73 was processed
All messages processed for tx 0x98f39774735d08de29fa005ce907d810e3afbd9c80a502f6ea15bf03b3c41a77
Transfer sent to destination chain!
✅ Successfully sent messages for chains: source ➡️ destination
```

## Crosschain tokens send (Native -> Synthetic)

This script allows to send directly Native tokens between source and destination chain. 

Prerequisites:
1. Warp route hyperlane contract need to be deployed on source and destination chains.
2. Validator/Relayer is up and run.
3. Validator signer funded on both chains.
4. .env file filled with (see contracts/env.example):
  a. SOURCE_HYPERLANE_TOKEN_ADDRESS - hyperlane native/ERC20 token
  b. XCHAIN_AMOUNT_WEI - amount of native tokens that need to be sent in WEI
  c. TOKENS_RECIPIENT - synthetic tokens receiver on destination chain

Go to /contracts folder and run in terminal:

```bash
>  ./script/xchain-send/xchain_send.sh
```


Note: Current anvil nodes state has predeployed hyperlane contract with unique validator address. To run on local machine it needs to be deployed hyperlane contracts from scratch(core, warp-route).



# Upgrade Hyperlane tokens to the espresso version

This upgrades hyperlane tokens to the espresso versions. Check EspressoNativeToken.sol / EspressoERC20.sol as implementation references.

Prerequisites:
1. DEPLOYER_PRIVATE_KEY is the proxy admin contracts owner.
2. .env file filled with (see contracts/env.example):
  a. SOURCE_HYPERLANE_TOKEN_ADDRESS - hyperlane native/ERC20 token on the source chain
  b. DESTINATION_HYPERLANE_TOKEN_ADDRESS - hyperlane native/ERC20 token on the destination chain
  c. SOURCE_PROXY_ADMIN_ADDRESS - proxy admin contract on the source chain
  d. DESTINATION_PROXY_ADMIN_ADDRESS - proxy admin contract on the destination chain

Go to /contracts folder and run in terminal:

```bash
>  ./script/token-upgrade/upgrade_tokens.sh
```

## Crosschain tokens send (Native -> Synthetic) wit NFT mint

Prerequisites:
1. Warp route hyperlane contract need to be deployed on source and destination chains.
2. Step `Upgrade Hyperlane tokens to the espresso version` is executed
3. Validator/Relayer is up and run.
4. Validator signer funded on both chains.
5. .env file filled with (see contracts/env.example):
  a. MARKETPLACE_ADDRESS - NFT contract address
  b. TREASURY_ADDRESS - Treasury address on destination that receive synthetic tokens in case of successful NFT mint

Go to /contracts folder and run in terminal:

```bash
>  ./script/xchain-full-send-mint/xchain_full_mint.sh
```

# Shutdown

```bash
> docker compose down
```
* In this repository/directory

```bash
> docker compose down
```

* Close the terminals running the anvil nodes.




TODO!!!
1. try to do full flow with local validator.
2. run and fix all tests