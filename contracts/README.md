## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build --via-ir
```

### Test

```shell
$ forge test --via-ir
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy DeployAndUpdateISMMultisig to specific chain

```shell
$ forge script script/DeployAndUpdateISMMultisig.s.sol:DeployAndUpdateISMMultisigScript  --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast --via-ir
```

### Deploy EspressoEscrow to source and destionation local chains
```shell
$ ./script/escrow/deploy-espresso-escrow-2-chain.sh
```

### Deploy DeployAndUpdateISMMultisig to source and destionation local chains
```shell
$ ./script/multisig-ism/deploy-ism-multisig-2-chains.sh
```

### Initiate cross-chain nft purchase from source chain
```shell
$ forge script script/xchain-full-send-mint/InitiateCrossChainNftPurchase.s.sol:InitiateCrossChainNftPurchaseScript  --rpc-url https://rpc.apechain.com/http --private-key <your_private_key> --broadcast --via-ir
```

### Collect fees fro IGP contract
```shell
$ forge script script/general/helpers/ClaimIgpFees.s.sol:ClaimIgpFeesScript  --rpc-url https://rpc.apechain.com/http --private-key <your_private_key> --broadcast --via-ir
```

### Bridge back tokens back to Native on source chain
```shell
$ forge script script/general/helpers/BridgeEspHypToSource.s.sol:BridgeEspHypToSourceScript  --rpc-url https://rpc.apechain.com/http --private-key <your_private_key> --broadcast --via-ir
```

### Change IGP fees beneficiary
```shell
$ forge script script/general/helpers/UpdateIgpBeneficiary.s.sol:UpdateIgpBeneficiaryScript  --rpc-url https://rpc.apechain.com/http --private-key <your_private_key> --broadcast --via-ir
```

### Change Contract ownerships
```shell
$ forge script script/general/helpers/UpdateOwnerships.s.sol:UpdateOwnershipsScript  --rpc-url https://rpc.apechain.com/http --private-key <your_private_key> --broadcast --via-ir
```


### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
