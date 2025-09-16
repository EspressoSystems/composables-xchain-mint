# Load .env
export $(grep -v '^#' .env | xargs)


BALANCE_HEX=$(cast call $SOURCE_TO_DESTINATION_TOKEN_ADDRESS "balanceOf(address)" $DEPLOYER_ADDRESS --rpc-url=$DESTINATION_CHAIN_RPC_URL)
export BALANCE_DECIMAL=$(cast --to-dec $BALANCE_HEX)

echo "Syntetic tokens balance on destination chain for $DEPLOYER_ADDRESS: $BALANCE_DECIMAL wei"

echo "Deployer $DEPLOYER_ADDRESS Native token balance:"
cast balance $DEPLOYER_ADDRESS --rpc-url=$DESTINATION_CHAIN_RPC_URL
