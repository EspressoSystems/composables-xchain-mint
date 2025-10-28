#!/usr/bin/env bash
set -euo pipefail

# Load .env
export $(grep -v '^#' ../../contracts/.env | xargs)

# Compute predicted token address
SALT="dest_to_source"
SALT_HASH=$(cast keccak $SALT)
TOKEN_ADDRESS=$(cast call $CREATE3_FACTORY_ADDRESS "getDeployed(address,bytes32)(address)" $DEPLOYER_ADDRESS $SALT_HASH --rpc-url $SOURCE_CHAIN_RPC_URL)
echo "Predicted token address: $TOKEN_ADDRESS"

# Deploy native on destination
export REMOTE_DOMAIN=$SOURCE_CHAIN_ID
export REMOTE_TOKEN=$TOKEN_ADDRESS
export HOOK_PAYMENT=$BRIDGE_BACK_PAYMENT_AMOUNT_WEI
export NFT_SALE_PRICE=$NFT_SALE_PRICE_WEI
export SCALE=1
export DECIMALS=18
export OWNER=$DEPLOYER_ADDRESS
export ADMIN=$DESTINATION_PROXY_ADMIN_ADDRESS
export SALT=$SALT
export ISM_ADDRESS=$DESTINATION_ISM_ADDRESS
forge script script/token/DeployEspHypNative.s.sol:DeployEspHypNativeScript --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

# Deploy synthetic on source
export REMOTE_DOMAIN=$DESTINATION_CHAIN_ID
export REMOTE_TOKEN=$TOKEN_ADDRESS
export MARKETPLACE_ADDRESS=$SOURCE_NFT_ADDRESS
export TREASURY_ADDRESS=$TREASURY_ADDRESS
export HOOK_PAYMENT=$BRIDGE_BACK_PAYMENT_AMOUNT_WEI
export GAS_FEES_DEPOSIT_WEI=$GAS_FEES_DEPOSIT_WEI
export ISM_ADDRESS=$SOURCE_ISM_ADDRESS
export ADMIN=$SOURCE_PROXY_ADMIN_ADDRESS
forge script script/token/DeployEspHypERC20.s.sol:DeployEspHypERC20Script --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

# Enroll remotes (handled in script)

echo "Warp route destination-to-source deployed with token address $TOKEN_ADDRESS on both chains"
echo "Update .env with DESTINATION_TO_SOURCE_TOKEN_ADDRESS=$TOKEN_ADDRESS"