# Load .env
export $(grep -v '^#' .env | xargs)

export MAILBOX_ADDRESS=$SOURCE_MAILBOX_ADDRESS
export ISM_ADDRESS=$SOURCE_ISM_ADDRESS
export ALLOWED_SOURCE_CHAIN_ID=$DESTINATION_CHAIN_ID
export ALLOWED_DESTINATION_CHAIN_ID=$DESTINATION_CHAIN_ID

forge script ../script/EspressoEscrow.s.sol:EspressoEscrowScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir
export SOURCE_ESPRESSO_ESCROW_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspressoEscrow") | .contractAddress
' "../broadcast/EspressoEscrow.s.sol/$SOURCE_CHAIN_ID/run-latest.json")

export SOURCE_NFT_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "MockERC721") | .contractAddress
' "../broadcast/EspressoEscrow.s.sol/$SOURCE_CHAIN_ID/run-latest.json")


export MAILBOX_ADDRESS=$DESTINATION_MAILBOX_ADDRESS
export ISM_ADDRESS=$DESTINATION_ISM_ADDRESS
export ALLOWED_SOURCE_CHAIN_ID=$SOURCE_CHAIN_ID
export ALLOWED_DESTINATION_CHAIN_ID=$SOURCE_CHAIN_ID

forge script script/escrow/EspressoEscrow.s.sol:EspressoEscrowScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir
export DESTINATION_ESPRESSO_ESCROW_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspressoEscrow") | .contractAddress
' "../broadcast/EspressoEscrow.s.sol/$DESTINATION_CHAIN_ID/run-latest.json")

export DESTINATION_NFT_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "MockERC721") | .contractAddress
' "../broadcast/EspressoEscrow.s.sol/$DESTINATION_CHAIN_ID/run-latest.json")


export ALLOWED_SENDER_ADDRESS=$DESTINATION_ESPRESSO_ESCROW_ADDRESS
export ESPRESSO_ESCROW_ADDRESS=$SOURCE_ESPRESSO_ESCROW_ADDRESS

forge script script/escrow/SetAllowedSenders.s.sol:SetAllowedSendersScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

export ALLOWED_SENDER_ADDRESS=$SOURCE_ESPRESSO_ESCROW_ADDRESS
export ESPRESSO_ESCROW_ADDRESS=$DESTINATION_ESPRESSO_ESCROW_ADDRESS

forge script script/escrow/SetAllowedSenders.s.sol:SetAllowedSendersScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir


echo "EspressoEscrow contract successfully deployed and configured on the source chain $SOURCE_ESPRESSO_ESCROW_ADDRESS"
echo "NFT contract successfully deployed and configured on the source chain $SOURCE_NFT_ADDRESS"
echo "EspressoEscrow contract successfully deployed and configured on the destination chain $DESTINATION_ESPRESSO_ESCROW_ADDRESS"
echo "NFT contract successfully deployed and configured on the destination chain $DESTINATION_NFT_ADDRESS"
echo "Allowed senders has been set"


