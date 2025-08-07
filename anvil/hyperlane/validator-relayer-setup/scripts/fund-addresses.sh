#!/bin/bash
set -e

export AWS_KMS_KEY_ID=alias/$VALIDATOR_KEY_ALIAS
export VALIDATOR_ADDRESS=`cast wallet address --aws`

# TODO maybe change at some point
export RELAYER_ADDRESS=$VALIDATOR_ADDRESS

echo "Validator address: $VALIDATOR_ADDRESS"
echo "Relayer address: $RELAYER_ADDRESS"

cast send  $VALIDATOR_ADDRESS --value 1ether --private-key $DEPLOYER_KEY --rpc-url $SOURCE_CHAIN_RPC_URL > /dev/null
echo "Validator address $VALIDATOR_ADDRESS  on source chain funded correctly."

cast send  $RELAYER_ADDRESS --value 1ether --private-key $DEPLOYER_KEY --rpc-url $DESTINATION_CHAIN_RPC_URL > /dev/null
echo "Relayer address $RELAYER_ADDRESS  on destination chain funded correctly."