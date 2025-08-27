# Load .env
export $(grep -v '^#' .env | xargs)

export DESTINATION_NFT_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "MockERC721") | .contractAddress
' "./broadcast/EspressoEscrow.s.sol/$DESTINATION_CHAIN_ID/run-latest.json")
cast call $DESTINATION_NFT_ADDRESS "nextTokenId()" --rpc-url=$DESTINATION_CHAIN_RPC_URL
