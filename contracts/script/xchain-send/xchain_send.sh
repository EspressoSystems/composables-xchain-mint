#!/usr/bin/env bash
set -euo pipefail

# Load .env
export $(grep -v '^#' .env | xargs)


BALANCE_HEX=$(cast call $SOURCE_HYPERLANE_TOKEN_ADDRESS "balanceOf(address)" $TOKENS_RECIPIENT --rpc-url=$DESTINATION_CHAIN_RPC_URL)
export BALANCE_SYNTHETIC_BEFORE=$(cast --to-dec $BALANCE_HEX)

export DEPLOYER_BALANCE_BEFORE=$(cast balance $DEPLOYER_ADDRESS --rpc-url=$DESTINATION_CHAIN_RPC_URL)
echo "Recipient $TOKENS_RECIPIENT synthetic tokens balance on destination chain before send: $BALANCE_SYNTHETIC_BEFORE wei"
echo "Deployer $DEPLOYER_ADDRESS native tokens balance on destination chain before send: $DEPLOYER_BALANCE_BEFORE wei"


forge script script/xchain-send/XChainSend.s.sol:XChainSendScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Sending $XCHAIN_AMOUNT_WEI tokens in wei  to the tokens to the recipient $TOKENS_RECIPIENT on destination chain, waiting 20 sec for relayer service confirmation..."
sleep 20

forge script script/xchain-send/XChainSendVerify.s.sol:XChainSendVerifyScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir


BALANCE_HEX=$(cast call $SOURCE_HYPERLANE_TOKEN_ADDRESS "balanceOf(address)" $TOKENS_RECIPIENT --rpc-url=$DESTINATION_CHAIN_RPC_URL)
export BALANCE_DECIMAL_AFTER=$(cast --to-dec $BALANCE_HEX)

export DEPLOYER_BALANCE_AFTER=$(cast balance $DEPLOYER_ADDRESS --rpc-url=$DESTINATION_CHAIN_RPC_URL)
echo "Recipient $TOKENS_RECIPIENT synthetic tokens balance on destination chain after send: $BALANCE_DECIMAL_AFTER wei"
echo "Deployer $DEPLOYER_ADDRESS native tokens balance on destination chain after send: $DEPLOYER_BALANCE_AFTER wei"



