Reference https://github.com/EspressoSystems/hyperlane-integration-poc

# Local anvil Rarible deployment.
Current 2 anvil nodes state includes deployed hyperlane core contract, warp route, mock NFT contract and upgraded version of Hyperlane native/tokens mint fake NFT during ETH tokens bridge. There is not need to redeploy it for the development. Just upgrading Hyperlane native/tokens according to the examples in scripts.

Note that current configuration considers a default trustedRelayerISM with Interchain Gas Paymaster that allows to pays fees on destination chain. This configuration uses Aggregation hook that aggregate merkleTree and interchainGasPaymaster hooks. Hyperlane setup use trustedRelayerISM as default ISM that fits current needs. Validator/Relayer keys presetup and open in .env.example file. For the prod release we will use our own multisigISM with espresso TEE verify.

## Launch source and destination chains with predeployed hyperlane contracts.


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


Go down to the `Run a validator and relayer.` and try to up and run validator and relayer. Then try to send test message by executing step `Send a test message between two chains` below. If hyperlane config errors apperas, then you have to setup hyperlane config and redeploy hyperlane contracts on both empty anvil chains from scratch. Execute instructions below and then try to send test message again:

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

# Run a validator and relayer.
1. Create and fill .env file according to the env.example.
2. Load env files by `export $(grep -v '^#' .env | xargs)`
3. Run docker-compose up in the separate terminal.
4. Check validator logs  `docker logs -f source-validator`. Run in the separate terminal.
5. Check relayer logs  `docker logs -f relayer`. Run in the separate terminal.



# Upgrade Hyperlane tokens to the espresso version with mock NFT contract

This upgrades hyperlane tokens to the espresso versions. Check EspHypNative.sol / EspHypERC20.sol as implementation references.

Prerequisites:
1. DEPLOYER_PRIVATE_KEY is the proxy admin contracts owner.
2. .env file filled with (see contracts/env.example):
  a. SOURCE_TO_DESTINATION_TOKEN_ADDRESS - hyperlane native/ERC20 token, source -> destination route
  b. DESTINATION_TO_SOURCE_TOKEN_ADDRESS - hyperlane native/ERC20 token, destination -> source route
  c. SOURCE_PROXY_ADMIN_ADDRESS - proxy admin contract on the source chain
  d. DESTINATION_PROXY_ADMIN_ADDRESS - proxy admin contract on the destination chain

Go to /contracts folder and run in terminal:

```bash
>  ./script/token-upgrade/upgrade_tokens.sh
```

## Crosschain tokens send (Native -> Synthetic) with NFT mint

Prerequisites:
1. 2 Anvil nodes with predefined state up.
2. Validator/Relayer is up and run.
3. .env file filled with (see contracts/env.example):
  a. DESTINATION_MARKETPLACE_ADDRESS - NFT contract address on destination chain
  b. TREASURY_ADDRESS - Treasury address on destination that receive synthetic tokens in case of successful NFT mint

Go to /contracts folder and run in terminal:

```bash
>  ./script/xchain-full-send-mint/xchain_full_mint_to_destination.sh
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


