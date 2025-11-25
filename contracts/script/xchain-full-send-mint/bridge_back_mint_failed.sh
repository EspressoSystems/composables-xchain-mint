#!/usr/bin/env bash
set -euo pipefail

# On CI, dump the environment for debugging
if [ "${CI:-}" = "true" ]; then
  echo "Environment variables:"
  env | sort
fi


export HYPERLANE_TOKEN_ADDRESS=$SOURCE_TO_DESTINATION_TOKEN_ADDRESS
# Zero address as an NFT recipient will trigger rollback of the tokens.
export RECIPIENT=$TOKENS_RECIPIENT

export RECIPIENT_BALANCE_BEFORE=$(cast balance $RECIPIENT --rpc-url=$SOURCE_CHAIN_RPC_URL)
forge script script/xchain-full-send-mint/XChainFullSend.s.sol:XChainFullSendScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Sending $XCHAIN_AMOUNT_WEI tokens in wei from the source chain to the tokens recipient $RECIPIENT on destination chain, waiting 15 sec for relayer service confirmation and rollback..."
sleep 15

forge script script/xchain-full-send-mint/XChainBackMintFailedVerify.s.sol:XChainBackMintFailedVerifyScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --via-ir

echo "Sent $XCHAIN_AMOUNT_WEI from  source -> destination -> source. Returned $XCHAIN_AMOUNT_WEI to the $RECIPIENT on source chain"
