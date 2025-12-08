# Production Fix Scripts

## Problem

The `espHypErc20` address on both NFT contracts is misconfigured:

| Chain | NFT | Current `espHypErc20` | Correct `espHypErc20` |
|-------|-----|----------------------|----------------------|
| Ape | `0xafD65ad351A4f14EE7a910f7fC924517B36a1D13` | `0x29b0a57Cb774f513653a90d3a185eb12D4AAc3ad` (EspHypNative) | `0x3e08Ad7C3fD70D08CdD2a11247dae18Eb06434FD` (EspHypERC20) |
| Rari | `0xafD65ad351A4f14EE7a910f7fC924517B36a1D13` | `0x3e08Ad7C3fD70D08CdD2a11247dae18Eb06434FD` (EspHypNative) | `0x29b0a57Cb774f513653a90d3a185eb12D4AAc3ad` (EspHypERC20) |

This causes cross-chain mints to fail with `NftPriceExceedsMsgValue` error because the NFT treats the EspHypERC20 caller as a native buyer.

## Solution

Each script (`FixApechain.s.sol`, `FixRarichain.s.sol`) does:

1. Deploy new EspNFT with correct `espHypErc20`
2. Deploy new EspHypERC20 implementation (with `setRariMarketplace`)
3. Upgrade EspHypERC20 proxy to new implementation
4. Call `setRariMarketplace(newNft)` on EspHypERC20
5. Verify all addresses are correctly linked

## Simulate

```bash
# Apechain
forge script script/prod/FixApechain.s.sol \
  --via-ir \
  --fork-url https://apechain.mainnet.on.espresso.network \
  --sender 0xb62b607FFAEb8dB7DE9FAD002656fd7B394e9168 \
  -vvv

# Rarichain
forge script script/prod/FixRarichain.s.sol \
  --via-ir \
  --fork-url https://rari.mainnet.on.espresso.network \
  --sender 0xb62b607FFAEb8dB7DE9FAD002656fd7B394e9168 \
  -vvv
```

## Deploy

```bash
# Apechain
forge script script/prod/FixApechain.s.sol \
  --via-ir \
  --fork-url https://apechain.mainnet.on.espresso.network \
  --broadcast \
  --private-key $DEPLOYER_PRIVATE_KEY

# Rarichain
forge script script/prod/FixRarichain.s.sol \
  --via-ir \
  --fork-url https://rari.mainnet.on.espresso.network \
  --broadcast \
  --private-key $DEPLOYER_PRIVATE_KEY
```

## Key Addresses

| Role | Address |
|------|---------|
| Deployer/Owner | `0xb62b607FFAEb8dB7DE9FAD002656fd7B394e9168` |
| ProxyAdmin | `0xAb0Ea363Dd1e8492425DB15798632485A94Aa17e` |
| Mailbox | `0x017be100600eCee055Eb27FA3b318E05Db79caD6` |

## Contracts Modified

- `src/EspHypERC20.sol`: Added `setRariMarketplace(address)` function
