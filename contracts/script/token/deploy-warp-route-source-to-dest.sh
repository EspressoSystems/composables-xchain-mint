#!/usr/bin/env bash
set -euo pipefail

# Load .env
export $(grep -v '^#' ../../contracts/.env | xargs)

# Compute predicted token address
SALT="source_to_dest"
SALT_HASH=$(cast keccak $SALT)
TOKEN_ADDRESS=$(cast call $CREATE3_FACTORY_ADDRESS "getDeployed(address,bytes32)(address)" $DEPLOYER_ADDRESS $SALT_HASH --rpc-url $SOURCE_CHAIN_RPC_URL)

echo "Predicted token address: $TOKEN_ADDRESS"

# Deploy native on source
export IS_NATIVE=true
export REMOTE_DOMAIN=$DESTINATION_CHAIN_ID
export REMOTE_TOKEN=$TOKEN_ADDRESS
export HOOK_PAYMENT=$BRIDGE_BACK_PAYMENT_AMOUNT_WEI
export NFT_SALE_PRICE=$NFT_SALE_PRICE_WEI
export SCALE=1
export DECIMALS=18
export OWNER=$DEPLOYER_ADDRESS
export ADMIN=$SOURCE_PROXY_ADMIN_ADDRESS
export SALT=$SALT
export MARKETPLACE_ADDRESS=$DESTINATION_NFT_ADDRESS # Not used for native
export TREASURY_ADDRESS=$TREASURY_ADDRESS # Not used for native

forge script script/token/DeployEspHypToken.s.sol:DeployEspHypTokenScript --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

# Deploy synthetic on destination
export IS_NATIVE=false
export REMOTE_DOMAIN=$SOURCE_CHAIN_ID
export REMOTE_TOKEN=$TOKEN_ADDRESS
export MARKETPLACE_ADDRESS=$DESTINATION_NFT_ADDRESS
export TREASURY_ADDRESS=$TREASURY_ADDRESS

forge script script/token/DeployEspHypToken.s.sol:DeployEspHypTokenScript --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

# Enroll remotes (already handled in script if REMOTE_TOKEN set)

echo "Warp route source-to-destination deployed with token address $TOKEN_ADDRESS on both chains"
echo "Update .env with SOURCE_TO_DESTINATION_TOKEN_ADDRESS=$TOKEN_ADDRESS"