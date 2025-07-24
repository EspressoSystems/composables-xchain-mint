# Load .env
export $(grep -v '^#' .env | xargs)

export D_NFT_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "MockERC721") | .contractAddress
' "./broadcast/EspressoEscrow.s.sol/$D_ORIGIN_CHAIN_ID/run-latest.json")
cast call $D_NFT_ADDRESS "nextTokenId()" --rpc-url=$DESTINATION_CHAIN_RPC_URL
