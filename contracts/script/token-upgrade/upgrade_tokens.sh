#!/usr/bin/env bash
set -euxo pipefail

# Load .env
export $(grep -v '^#' .env | xargs)

echo "Upgrading Native token on the source chain. (source Native -> destination synthetic route)."
export MAILBOX_ADDRESS=$SOURCE_MAILBOX_ADDRESS
export PROXY_ADMIN_ADDRESS=$SOURCE_PROXY_ADMIN_ADDRESS
export HYPERLANE_TOKEN_ADDRESS=$SOURCE_TO_DESTINATION_TOKEN_ADDRESS
export DESTINATION_DOMAIN_ID=$DESTINATION_CHAIN_ID
forge script script/token-upgrade/UpgradeNativeToken.s.sol:UpgradeNativeTokenScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Upgrading Synthetic token on the destination chain. (source Native -> destination synthetic route)."
export MAILBOX_ADDRESS=$DESTINATION_MAILBOX_ADDRESS
export PROXY_ADMIN_ADDRESS=$DESTINATION_PROXY_ADMIN_ADDRESS
export HYPERLANE_TOKEN_ADDRESS=$SOURCE_TO_DESTINATION_TOKEN_ADDRESS
export MARKETPLACE_ADDRESS=$DESTINATION_MARKETPLACE_ADDRESS
forge script script/token-upgrade/UpgradeERC20Token.s.sol:UpgradeERC20TokenScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Upgrade source -> destination complete."


echo "Upgrading Native token on the destination chain. (destination Native -> source synthetic route)."
export MAILBOX_ADDRESS=$DESTINATION_MAILBOX_ADDRESS
export PROXY_ADMIN_ADDRESS=$DESTINATION_PROXY_ADMIN_ADDRESS
export HYPERLANE_TOKEN_ADDRESS=$DESTINATION_TO_SOURCE_TOKEN_ADDRESS
export DESTINATION_DOMAIN_ID=$SOURCE_CHAIN_ID
forge script script/token-upgrade/UpgradeNativeToken.s.sol:UpgradeNativeTokenScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Upgrading Synthetic token on the destination chain. (source Native -> destination synthetic route)."
export MAILBOX_ADDRESS=$SOURCE_MAILBOX_ADDRESS
export PROXY_ADMIN_ADDRESS=$SOURCE_PROXY_ADMIN_ADDRESS
export HYPERLANE_TOKEN_ADDRESS=$DESTINATION_TO_SOURCE_TOKEN_ADDRESS
export MARKETPLACE_ADDRESS=$SOURCE_MARKETPLACE_ADDRESS
forge script script/token-upgrade/UpgradeERC20Token.s.sol:UpgradeERC20TokenScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Upgrade destination -> source complete."
