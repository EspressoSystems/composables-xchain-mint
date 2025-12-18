#!/usr/bin/env bash
set -euxo pipefail

# Load .env
export $(grep -v '^#' .env | xargs)

# APE native update
echo "Upgrading Native token on the source chain. (source native -> destination synthetic route)."
export MAILBOX_ADDRESS=$SOURCE_MAILBOX_ADDRESS
export PROXY_ADMIN_ADDRESS=$SOURCE_PROXY_ADMIN_ADDRESS
export HYPERLANE_TOKEN_ADDRESS=$SOURCE_TO_DESTINATION_TOKEN_ADDRESS
export DESTINATION_DOMAIN_ID=$DESTINATION_CHAIN_ID
# SALE_TIME_START is reversed due to APE entry point and NFT on Rari
export SALE_TIME_START=1765814400
export PRICE_ADMIN_ADDRESS=0xD50a66B631544454b21BC32f5A2723428dbf3073
# Should be Ape price
export SOURCE_SALE_PRICE_WEI=12000000000000000000
forge script script/token-upgrade/UpgradeNativeToken.s.sol:UpgradeNativeTokenScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

# APE erc20 update
echo "Upgrading Synthetic token on the destination chain. (source native -> destination synthetic route)."
export MAILBOX_ADDRESS=$DESTINATION_MAILBOX_ADDRESS
export PROXY_ADMIN_ADDRESS=$DESTINATION_PROXY_ADMIN_ADDRESS
export NFT_ADDRESS=$DESTINATION_NFT_ADDRESS
export DESTINATION_DOMAIN_ID=$SOURCE_CHAIN_ID
# ETH on rari 0.0005 ETH
export BRIDGE_BACK_PAYMENT_AMOUNT_WEI=500000000000000
forge script script/token-upgrade/UpgradeERC20Token.s.sol:UpgradeERC20TokenScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Upgrade source -> destination complete."

# RARI native update
echo "Upgrading Native token on the destination chain. (destination native -> source synthetic route)."
export HYPERLANE_TOKEN_ADDRESS=$DESTINATION_TO_SOURCE_TOKEN_ADDRESS
# SALE_TIME_START is reversed due to RARI entry point and NFT on Ape
export SALE_TIME_START=1765202400
export PRICE_ADMIN_ADDRESS=0x740812DC83d6cE2a9bdde35aF54799097f355da1
# Should be ETH price, on rari
export SOURCE_SALE_PRICE_WEI=1000000000000000
forge script script/token-upgrade/UpgradeNativeToken.s.sol:UpgradeNativeTokenScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

# RARI erc20 update
echo "Upgrading Synthetic token on the destination chain. (source native -> destination synthetic route)."
export MAILBOX_ADDRESS=$SOURCE_MAILBOX_ADDRESS
export PROXY_ADMIN_ADDRESS=$SOURCE_PROXY_ADMIN_ADDRESS
export NFT_ADDRESS=$SOURCE_NFT_ADDRESS
export DESTINATION_DOMAIN_ID=$DESTINATION_CHAIN_ID
# APE on apechain 0.01 APE
export BRIDGE_BACK_PAYMENT_AMOUNT_WEI=10000000000000000
forge script script/token-upgrade/UpgradeERC20Token.s.sol:UpgradeERC20TokenScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Upgrade destination -> source complete."
