#!/usr/bin/env bash
set -euxo pipefail

# Load .env
export $(grep -v '^#' .env | xargs)

forge script script/DeployCREATE3Factory.s.sol:DeployCREATE3FactoryScript --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

SOURCE_CREATE3_FACTORY_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "CREATE3Factory") | .contractAddress
' "./broadcast/DeployCREATE3Factory.s.sol/$SOURCE_CHAIN_ID/run-latest.json")

forge script script/DeployCREATE3Factory.s.sol:DeployCREATE3FactoryScript --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

DESTINATION_CREATE3_FACTORY_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "CREATE3Factory") | .contractAddress
' "./broadcast/DeployCREATE3Factory.s.sol/$DESTINATION_CHAIN_ID/run-latest.json")

echo "CREATE3Factory deployed on source chain at $SOURCE_CREATE3_FACTORY_ADDRESS"
echo "CREATE3Factory deployed on destination chain at $DESTINATION_CREATE3_FACTORY_ADDRESS"

if [ "$SOURCE_CREATE3_FACTORY_ADDRESS" != "$DESTINATION_CREATE3_FACTORY_ADDRESS" ]; then
  echo "Error: Factory addresses do not match across chains!"
  exit 1
fi

echo "Add CREATE3_FACTORY_ADDRESS=$SOURCE_CREATE3_FACTORY_ADDRESS to .env"