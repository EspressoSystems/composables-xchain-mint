
## Deployment Addresses

This is the first deployment on Rari and Apechain testnets:

```bash
# DEPLOYER ADDRESS
DEPLOYER_PRIVATE_KEY=
DEPLOYER_ADDRESS=0xAF390e47486F122880c5A80F9470020C6a3F67bA

# RPCs
SOURCE_CHAIN_RPC_URL=https://rari-testnet.calderachain.xyz/http
DESTINATION_CHAIN_RPC_URL=https://apechain-tnet.rpc.caldera.xyz/http
SOURCE_CHAIN_ID=1918988905
DESTINATION_CHAIN_ID=3313939

# Hyperlane
VALIDATOR_ADDRESS=0xe00b18D1A8197973f924eCC6EBBcD475F9D290aF

SOURCE_MAILBOX_ADDRESS=0xeD69A293489fBfBcda6158739759f0d4E23FDB7f
SOURCE_ISM_ADDRESS=0xAF390e47486F122880c5A80F9470020C6a3F67bA

DESTINATION_MAILBOX_ADDRESS=0xeD69A293489fBfBcda6158739759f0d4E23FDB7f
DESTINATION_ISM_ADDRESS=0xAF390e47486F122880c5A80F9470020C6a3F67bA

SOURCE_PROXY_ADMIN_ADDRESS=0x03129675f3Ea8a8606035a164D781086C3fDE9FB
DESTINATION_PROXY_ADMIN_ADDRESS=0x03129675f3Ea8a8606035a164D781086C3fDE9FB

DESTINATION_NATIVE_TOKEN_ADDRES=0xF61993De848A40f4fa9F03dc7d3cC75d4686eb1A
DESTINATION_SYN_TOKEN_ADDRES=0x946a17d001365c127FB127A8ac92713DAEEF8F8b

SOURCE_NATIVE_TOKEN_ADDRESS=0x4E87B8Ac718922D838886e1c2bF94b65124d9509
SOURCE_SYN_TOKEN_ADDRESS=0xa9D12f59D3a602A603c0293A6a1e595C05599135

# Env variables for sending tokens and minting NFT
# Currently treasury address is the 4th address from the test mnemonic
TREASURY_ADDRESS=0xAF390e47486F122880c5A80F9470020C6a3F67bA
SOURCE_MARKETPLACE_ADDRESS=0xE5ab5E0a2ab5Fff430D6914850b383846A68132B
DESTINATION_MARKETPLACE_ADDRESS=0xE5ab5E0a2ab5Fff430D6914850b383846A68132B
BLACKLISTED_NFT_RECIPIENT=0x4b5ea2c96728F6C076cD63E0050B5A420E136e6a

# Configs
XCHAIN_AMOUNT_WEI=100000000000000000
TOKENS_RECIPIENT=$DEPLOYER_ADDRESS
NFT_SALE_PRICE_WEI=100000000000000000
BRIDGE_BACK_PAYMENT_AMOUNT_WEI=1000000000000000

# Espresso Tee Verifier
SOURCE_ESPRESSO_TEE_VERIFIER_ADDRESS=0x0000000000000000000000000000000000000000
DESTINATION_ESPRESSO_TEE_VERIFIER_ADDRESS=0x0000000000000000000000000000000000000000
```

## Mint NFTs

```bash
export XCHAIN_AMOUNT_WEI=100000000000000000
export RECIPIENT=0x9B676130513451716fF39e3d7e099A1A3a5574bD
# HypNative contract on Rari chain, where the minting flow is started
export SOURCE_NATIVE_TOKEN_ADDRESS=0x4E87B8Ac718922D838886e1c2bF94b65124d9509
export RPC_URL=https://rari-testnet.calderachain.xyz/http
export PRIVATE_KEY=

# Left padding needed
RECIPIENT_BYTES32=0x0000000000000000000000009b676130513451716ff39e3d7e099a1a3a5574bd
PAY_GAS_FEES=$(cast --to-wei 0.1 ether)
TOTAL_VALUE=$((XCHAIN_AMOUNT_WEI + PAY_GAS_FEES))

DATA=$(cast calldata "initiateCrossChainNftPurchase(bytes32)" $RECIPIENT_BYTES32)

cast send $SOURCE_NATIVE_TOKEN_ADDRESS \
  "$DATA" \
  --private-key $PRIVATE_KEY \
  --value $TOTAL_VALUE \
  --rpc-url $RPC_URL -vvv
```

## Contracts Needed to Deploy (Testnet)

### Deployment Hyperlane Core

Deployed through `hyperlane core deploy  --config <CONFIG-FILE>`:

```yaml
# destination.yaml
owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
defaultIsm:
  type: trustedRelayerIsm
  relayer: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
defaultHook:
  type: aggregationHook
  hooks:
    - owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
      type: interchainGasPaymaster
      beneficiary: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
      oracleKey: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
      overhead:
        destination: 75000
      oracleConfig:
        destination:
            gasPrice: "1058512358"
            tokenDecimals: 18
            tokenExchangeRate: "11000000000"
    - type: merkleTreeHook
requiredHook:
  owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  type: interchainGasPaymaster
  beneficiary: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  oracleKey: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  overhead:
    destination: 75000
  oracleConfig:
    destination:
      gasPrice: "1058512358"
      tokenExchangeRate: "11000000000"
      tokenDecimals: 18
proxyAdmin:
  owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
```

```yaml
# source.yaml
owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
defaultIsm:
  type: trustedRelayerIsm
  relayer: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
defaultHook:
  type: aggregationHook
  hooks:
    - owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
      type: interchainGasPaymaster
      beneficiary: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
      oracleKey: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
      overhead:
        destination: 75000
      oracleConfig:
        destination:
            gasPrice: "1058512358"
            tokenDecimals: 18
            tokenExchangeRate: "11000000000"
    - type: merkleTreeHook
requiredHook:
  owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  type: interchainGasPaymaster
  beneficiary: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  oracleKey: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  overhead:
    destination: 75000
  oracleConfig:
    destination:
      gasPrice: "1058512358"
      tokenExchangeRate: "11000000000"
      tokenDecimals: 18
proxyAdmin:
  owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
```

The above deployments resulted in the following addresses:


```yaml
# destination
staticMerkleRootMultisigIsmFactory: "0x266c3f7A56CA7Aa6Dd39041d2161559124d5b371"
staticMessageIdMultisigIsmFactory: "0x9c504CB425007fc6015f629543a350f97Ab549A7"
staticAggregationIsmFactory: "0xCF5742965720dc5b1fDFBe63171cD0636D89236A"
staticAggregationHookFactory: "0x4c976Bc6Fa6Df0960f1509F1E375a86d388AC7de"
domainRoutingIsmFactory: "0x87070304894db541557a64BFd19eFC4C89AB6f2d"
staticMerkleRootWeightedMultisigIsmFactory: "0x973D20FEFa7CdE2Eb5aEb9f845d15b001a36b9Ef"
staticMessageIdWeightedMultisigIsmFactory: "0xc48Aff18B2e097Da6B3a9523F5842749E6bF890B"
proxyAdmin: "0x03129675f3Ea8a8606035a164D781086C3fDE9FB"
mailbox: "0xeD69A293489fBfBcda6158739759f0d4E23FDB7f"
interchainAccountRouter: "0xB7f9e8a5314Fa101E021a8c0e4413d0e117EF904"
validatorAnnounce: "0x1ac497F2bdC984b6394088fcf59f32aFd8F5C094"
testRecipient: "0xb010Bbdba4D6b2e832d160D81c571CCCc6a8dDcd"
merkleTreeHook: "0xE44bbb42F5c52e24Cf375E496493fe35bea09246"
interchainGasPaymaster: "0x0B44929F9cC3Ce63d5bF0A1dA7763DCDaD1190EF"
```


```yaml
# source
staticMerkleRootMultisigIsmFactory: "0x266c3f7A56CA7Aa6Dd39041d2161559124d5b371"
staticMessageIdMultisigIsmFactory: "0x9c504CB425007fc6015f629543a350f97Ab549A7"
staticAggregationIsmFactory: "0xCF5742965720dc5b1fDFBe63171cD0636D89236A"
staticAggregationHookFactory: "0x4c976Bc6Fa6Df0960f1509F1E375a86d388AC7de"
domainRoutingIsmFactory: "0x87070304894db541557a64BFd19eFC4C89AB6f2d"
staticMerkleRootWeightedMultisigIsmFactory: "0x973D20FEFa7CdE2Eb5aEb9f845d15b001a36b9Ef"
staticMessageIdWeightedMultisigIsmFactory: "0xc48Aff18B2e097Da6B3a9523F5842749E6bF890B"
proxyAdmin: "0x03129675f3Ea8a8606035a164D781086C3fDE9FB"
mailbox: "0xeD69A293489fBfBcda6158739759f0d4E23FDB7f"
interchainAccountRouter: "0xB7f9e8a5314Fa101E021a8c0e4413d0e117EF904"
validatorAnnounce: "0x1ac497F2bdC984b6394088fcf59f32aFd8F5C094"
testRecipient: "0xb010Bbdba4D6b2e832d160D81c571CCCc6a8dDcd"
merkleTreeHook: "0xE44bbb42F5c52e24Cf375E496493fe35bea09246"
interchainGasPaymaster: "0x0B44929F9cC3Ce63d5bF0A1dA7763DCDaD1190EF"
```

### Deployment Hyperlane Warp

Deployed through `hyperlane warp send --symbol ETH --registry hyperlane`

```yaml
# destination-deploy.yaml
destination:
  interchainSecurityModule:
    type: trustedRelayerIsm
    relayer: "0xe00b18D1A8197973f924eCC6EBBcD475F9D290aF"
  isNft: false
  owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  proxyAdmin:
    address: "0x03129675f3Ea8a8606035a164D781086C3fDE9FB"
    owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  type: synthetic
  symbol: ECWETH
  name: Espresso Composables WETH
  decimals: 18
source:
  interchainSecurityModule:
    type: trustedRelayerIsm
    relayer: "0xe00b18D1A8197973f924eCC6EBBcD475F9D290aF"
  isNft: false
  owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  proxyAdmin:
    address: "0x03129675f3Ea8a8606035a164D781086C3fDE9FB"
    owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  type: native
  symbol: ECWETH
  name: Espresso Composables WETH
  decimals: 18
```

```yaml
# source-deploy.yaml
destination:
  interchainSecurityModule:
    relayer: "0xe00b18D1A8197973f924eCC6EBBcD475F9D290aF"
    type: trustedRelayerIsm
  isNft: false
  owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  proxyAdmin:
    address: "0x03129675f3Ea8a8606035a164D781086C3fDE9FB"
    owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  type: native
  symbol: ECWETH
  name: Espresso Composables WETH
  decimals: 18
source:
  interchainSecurityModule:
    relayer: "0xe00b18D1A8197973f924eCC6EBBcD475F9D290aF"
    type: trustedRelayerIsm
  isNft: false
  owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  proxyAdmin:
    address: "0x03129675f3Ea8a8606035a164D781086C3fDE9FB"
    owner: "0xAF390e47486F122880c5A80F9470020C6a3F67bA"
  type: synthetic
  symbol: ECWETH
  name: Espresso Composables WETH
  decimals: 18
```

The above deployment resulted in the following config files:

```yaml
# destination-config.yaml
# yaml-language-server: $schema=../schema.json
tokens:
  - addressOrDenom: "0x946a17d001365c127FB127A8ac92713DAEEF8F8b"
    chainName: destination
    connections:
      - token: ethereum|source|0x4E87B8Ac718922D838886e1c2bF94b65124d9509
    decimals: 18
    name: Espresso Composables WETH
    standard: EvmHypSynthetic
    symbol: ECWETH
  - addressOrDenom: "0x4E87B8Ac718922D838886e1c2bF94b65124d9509"
    chainName: source
    connections:
      - token: ethereum|destination|0x946a17d001365c127FB127A8ac92713DAEEF8F8b
    decimals: 18
    name: Ether
    standard: EvmHypNative
    symbol: ECWETH
```

```yaml
# source-config.yaml
# yaml-language-server: $schema=../schema.json
tokens:
  - addressOrDenom: "0xF61993De848A40f4fa9F03dc7d3cC75d4686eb1A"
    chainName: destination
    connections:
      - token: ethereum|source|0xa9D12f59D3a602A603c0293A6a1e595C05599135
    decimals: 18
    name: Ether
    standard: EvmHypNative
    symbol: ECWETH
  - addressOrDenom: "0xa9D12f59D3a602A603c0293A6a1e595C05599135"
    chainName: source
    connections:
      - token: ethereum|destination|0xF61993De848A40f4fa9F03dc7d3cC75d4686eb1A
    decimals: 18
    name: Espresso Composables WETH
    standard: EvmHypSynthetic
    symbol: ECWETH
```

## Deployment of MockERC721

- Contract: `contracts/src/mocks/MockERC721.sol`
- Script: `contracts/script/nft/deploy-nft-2-chains.sh`
- CLI:

```bash
forge create MockERC721 --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $PRIVATE_KEY --broadcast --via-ir --constructor-args $BLACKLISTED_ADDRESS
```

```bash
forge create MockERC721 --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $PRIVATE_KEY --broadcast --via-ir --constructor-args $BLACKLISTED_ADDRESS
```

## Deployment of EspHypNative & EspHypERC20 (and upgrade)

The Hyperlane contracts are upgraded using Espresso-modified versions:

- Contracts:
    - `contracts/src/EspHypNative.sol`
    - `contracts/src/EspHypERC20.sol`
- Script: `contracts/script/token-upgrade/upgrade_tokens.sh`
- CLI:

```yaml
forge create src/EspHypNative.sol:EspHypNative \
  --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir --rpc-url $SOURCE_CHAIN_RPC_URL \
  --constructor-args 1 $SOURCE_MAILBOX_ADDRESS
```

```yaml
forge create src/EspHypERC20.sol:EspHypERC20 --private-key $DEPLOYER_PRIVATE_KEY  --broadcast --via-ir --rpc-url $DESTINATION_CHAIN_RPC_URL --constructor-args 18 1 $DESTINATION_MAILBOX_ADDRESS --from $DEPLOYER_ADDRESS
```

```yaml
forge create src/EspHypNative.sol:EspHypNative \
  --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir --rpc-url $DESTINATION_CHAIN_RPC_URL \
  --constructor-args 1 $DESTINATION_MAILBOX_ADDRESS
```

```yaml
forge create src/EspHypERC20.sol:EspHypERC20 --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir --rpc-url $SOURCE_CHAIN_RPC_URL --constructor-args 18 1 $SOURCE_MAILBOX_ADDRESS --from $DEPLOYER_ADDRESS
```