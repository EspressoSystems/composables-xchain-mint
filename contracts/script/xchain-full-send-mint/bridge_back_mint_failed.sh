#!/usr/bin/env bash
set -euo pipefail

# On CI, dump the environment for debugging
if [ "${CI:-}" = "true" ]; then
  echo "Environment variables:"
  env | sort
fi


export HYPERLANE_TOKEN_ADDRESS=$SOURCE_TO_DESTINATION_TOKEN_ADDRESS
export RECIPIENT=$TOKENS_RECIPIENT

# Remove minter role to fail external call and test back mint functionality.
MINTER_ROLE=0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6

cast send $DESTINATION_NFT_ADDRESS "revokeRole(bytes32,address)" $MINTER_ROLE $HYPERLANE_TOKEN_ADDRESS  --private-key $DEPLOYER_PRIVATE_KEY --rpc-url=$DESTINATION_CHAIN_RPC_URL

export RECIPIENT_BALANCE_BEFORE=$(cast balance $RECIPIENT --rpc-url=$SOURCE_CHAIN_RPC_URL)
forge script script/xchain-full-send-mint/XChainFullSend.s.sol:XChainFullSendScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Sending $XCHAIN_AMOUNT_WEI tokens in wei from the source chain to the tokens recipient $RECIPIENT on destination chain. with revoked minter role, waiting 15 sec for relayer service confirmation and rollback..."
sleep 15

# Grant minter role back.
cast send $DESTINATION_NFT_ADDRESS "grantRole(bytes32,address)" $MINTER_ROLE $HYPERLANE_TOKEN_ADDRESS  --private-key $DEPLOYER_PRIVATE_KEY --rpc-url=$DESTINATION_CHAIN_RPC_URL

forge script script/xchain-full-send-mint/XChainBackMintFailedVerify.s.sol:XChainBackMintFailedVerifyScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --via-ir

echo "Sent $XCHAIN_AMOUNT_WEI from  source -> destination -> source. Returned $XCHAIN_AMOUNT_WEI to the $RECIPIENT on source chain"
