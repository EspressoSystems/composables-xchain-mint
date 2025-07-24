# Load .env
export $(grep -v '^#' .env | xargs)

export MAILBOX_ADDRESS=$S_MAILBOX_ADDRESS
export ISM_ADDRESS=$S_ISM_ADDRESS
export ORIGIN_CHAIN_ID=$S_ORIGIN_CHAIN_ID
export DESTINATION_CHAIN_ID=$S_DESTINATION_CHAIN_ID

forge script script/EspressoEscrow.s.sol:EspressoEscrowScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir
export S_ESPRESSO_ESCROW_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspressoEscrow") | .contractAddress
' "./broadcast/EspressoEscrow.s.sol/$S_ORIGIN_CHAIN_ID/run-latest.json")


export MAILBOX_ADDRESS=$D_MAILBOX_ADDRESS
export ISM_ADDRESS=$D_ISM_ADDRESS
export ORIGIN_CHAIN_ID=$D_ORIGIN_CHAIN_ID
export DESTINATION_CHAIN_ID=$D_DESTINATION_CHAIN_ID

forge script script/EspressoEscrow.s.sol:EspressoEscrowScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir
export D_ESPRESSO_ESCROW_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspressoEscrow") | .contractAddress
' "./broadcast/EspressoEscrow.s.sol/$D_ORIGIN_CHAIN_ID/run-latest.json")


echo "EspressoEscrow contract successfully deployed and configured on the source chain $S_ESPRESSO_ESCROW_ADDRESS"
echo "EspressoEscrow contract successfully deployed and configured on the destination chain $D_ESPRESSO_ESCROW_ADDRESS"


