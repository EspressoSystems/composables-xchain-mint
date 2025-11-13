#!/usr/bin/env bash
set -euo pipefail

# Load .env
export $(grep -v '^#' .env | xargs)

export BASE_IMAGE_URI=$DESTINATION_BASE_IMAGE_URI
export CHAIN_NAME=$DESTINATION_CHAIN_NAME
export HYPERLANE_TOKEN_ADDRESS=$SOURCE_TO_DESTINATION_TOKEN_ADDRESS

forge script script/nft/EspNFT.s.sol:EspNFTScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

export NFT_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspNFT") | .contractAddress
' "./broadcast/EspNFT.s.sol/$DESTINATION_CHAIN_ID/run-latest.json")

echo "EspNFT contract successfully deployed and configured on the destination $CHAIN_NAME chain $NFT_ADDRESS"

echo "Upgrading Native token on the source chain. (source native -> destination synthetic route)."
export MAILBOX_ADDRESS=$SOURCE_MAILBOX_ADDRESS
export PROXY_ADMIN_ADDRESS=$SOURCE_PROXY_ADMIN_ADDRESS
export DESTINATION_DOMAIN_ID=$DESTINATION_CHAIN_ID
forge script script/token-upgrade/UpgradeNativeToken.s.sol:UpgradeNativeTokenScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Upgrading Synthetic token on the destination $CHAIN_NAME chain. (source native -> destination synthetic route)."
export MAILBOX_ADDRESS=$DESTINATION_MAILBOX_ADDRESS
export PROXY_ADMIN_ADDRESS=$DESTINATION_PROXY_ADMIN_ADDRESS
export DESTINATION_DOMAIN_ID=$SOURCE_CHAIN_ID
forge script script/token-upgrade/UpgradeERC20Token.s.sol:UpgradeERC20TokenScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Upgrade source -> destination $CHAIN_NAME chain complete."