# Load .env
export $(grep -v '^#' .env | xargs)

export SOURCE_ESPRESSO_ESCROW_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspressoEscrow") | .contractAddress
' "./broadcast/EspressoEscrow.s.sol/$SOURCE_CHAIN_ID/run-latest.json")
export DESTINATION_ESPRESSO_ESCROW_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspressoEscrow") | .contractAddress
' "./broadcast/EspressoEscrow.s.sol/$DESTINATION_CHAIN_ID/run-latest.json")

forge script script/XChainMint.s.sol:XChainMintScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Sending message to NFT contract $DESTINATION_ESPRESSO_ESCROW_ADDRESS on destination chain"
