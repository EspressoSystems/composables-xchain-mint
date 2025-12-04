#!/usr/bin/env bash
set -euo pipefail

# Load .env
export $(grep -v '^#' .env | xargs)

export BASE_IMAGE_URI=$SOURCE_BASE_IMAGE_URI
export CHAIN_NAME=$SOURCE_CHAIN_NAME
export HYPERLANE_TOKEN_ADDRESS=$DESTINATION_TO_SOURCE_TOKEN_ADDRESS
export NFT_NAME='Espresso Brews Rari'

forge script script/nft/EspNFT.s.sol:EspNFTScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

SOURCE_NFT_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspNFT") | .contractAddress
' "./broadcast/EspNFT.s.sol/$SOURCE_CHAIN_ID/run-latest.json")

export BASE_IMAGE_URI=$DESTINATION_BASE_IMAGE_URI
export CHAIN_NAME=$DESTINATION_CHAIN_NAME
export HYPERLANE_TOKEN_ADDRESS=$SOURCE_TO_DESTINATION_TOKEN_ADDRESS
export NFT_NAME='Espresso Brews Ape'

forge script script/nft/EspNFT.s.sol:EspNFTScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

DESTINATION_NFT_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspNFT") | .contractAddress
' "./broadcast/EspNFT.s.sol/$DESTINATION_CHAIN_ID/run-latest.json")


echo "EspNFT contract successfully deployed and configured on the source $SOURCE_CHAIN_NAME chain $SOURCE_NFT_ADDRESS"
echo "EspNFT contract successfully deployed and configured on the destination $DESTINATION_CHAIN_NAME chain $DESTINATION_NFT_ADDRESS"
