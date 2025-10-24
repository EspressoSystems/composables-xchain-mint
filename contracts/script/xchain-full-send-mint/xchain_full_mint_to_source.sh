#!/usr/bin/env bash
set -euo pipefail

# On CI, dump the environment for debugging
if [ "${CI:-}" = "true" ]; then
  echo "Environment variables:"
  env | sort
fi


export HYPERLANE_TOKEN_ADDRESS=$DESTINATION_TO_SOURCE_TOKEN_ADDRESS
export NFT_ADDRESS=$SOURCE_NFT_ADDRESS
export RECIPIENT=$TOKENS_RECIPIENT

BALANCE_HEX=$(cast call $HYPERLANE_TOKEN_ADDRESS "balanceOf(address)" $TREASURY_ADDRESS --rpc-url=$SOURCE_CHAIN_RPC_URL)
export BALANCE_SYNTHETIC_BEFORE=$(cast --to-dec $BALANCE_HEX)

export DEPLOYER_BALANCE_BEFORE=$(cast balance $DEPLOYER_ADDRESS --rpc-url=$SOURCE_CHAIN_RPC_URL)

echo "Treasury $TREASURY_ADDRESS synthetic tokens balance on source chain before send: $BALANCE_SYNTHETIC_BEFORE wei"
echo "Deployer $DEPLOYER_ADDRESS native tokens balance on source chain before send: $DEPLOYER_BALANCE_BEFORE wei"

NFTS_COUNT_HEX=$(cast call $NFT_ADDRESS "lastTokenId()" --rpc-url=$SOURCE_CHAIN_RPC_URL)
export NFTS_COUNT_BEFORE=$(cast --to-dec $NFTS_COUNT_HEX)

echo "Minted NFTs count before xchain mint $NFTS_COUNT_BEFORE"


forge script script/xchain-full-send-mint/XChainFullSend.s.sol:XChainFullSendScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Sending $XCHAIN_AMOUNT_WEI tokens in wei from the destination chain to the tokens to the recipient $TREASURY_ADDRESS on source chain, waiting 20 sec for relayer service confirmation..."
sleep 20

forge script script/xchain-full-send-mint/XChainNFTVerify.s.sol:XChainNFTVerifyScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir


BALANCE_HEX=$(cast call $HYPERLANE_TOKEN_ADDRESS "balanceOf(address)" $TREASURY_ADDRESS --rpc-url=$SOURCE_CHAIN_RPC_URL)
BALANCE_DECIMAL_AFTER=$(cast --to-dec $BALANCE_HEX)

DEPLOYER_BALANCE_AFTER=$(cast balance $DEPLOYER_ADDRESS --rpc-url=$SOURCE_CHAIN_RPC_URL)
echo "Recipient $TREASURY_ADDRESS synthetic tokens balance on source chain after send: $BALANCE_DECIMAL_AFTER wei"
echo "Deployer $DEPLOYER_ADDRESS native tokens balance on source chain after send: $DEPLOYER_BALANCE_AFTER wei"


NFTS_COUNT_HEX=$(cast call $NFT_ADDRESS "lastTokenId()" --rpc-url=$SOURCE_CHAIN_RPC_URL)
NFTS_COUNT_AFTER=$(cast --to-dec $NFTS_COUNT_HEX)

echo "Minted NFTs count after xchain mint $NFTS_COUNT_AFTER destination -> source"
