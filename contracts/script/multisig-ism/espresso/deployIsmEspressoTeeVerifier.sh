#!/usr/bin/env bash
set -euxo pipefail

# Load .env
export $(grep -v '^#' .env | xargs)

echo "Deploying ISMEspressoTEEVerifier on the source chain"
ESPRESSO_TEE_VERIFIER_ADDRESS=$SOURCE_ESPRESSO_TEE_VERIFIER_ADDRESS
forge script script/multisig-ism/espresso/ISMEspressoTEEVerifier.s.sol:ISMEspressoTEEVerifierScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Deploying ISMEspressoTEEVerifier on the destination chain"
ESPRESSO_TEE_VERIFIER_ADDRESS=$DESTINATION_ESPRESSO_TEE_VERIFIER_ADDRESS
forge script script/multisig-ism/espresso/ISMEspressoTEEVerifier.s.sol:ISMEspressoTEEVerifierScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "ISM espresso verifiers deployed"
