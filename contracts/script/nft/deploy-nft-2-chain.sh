# Load .env
export $(grep -v '^#' .env | xargs)

forge script script/nft/NFT.s.sol:NFTScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

SOURCE_NFT_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "MockERC721") | .contractAddress
' "./broadcast/NFT.s.sol/$SOURCE_CHAIN_ID/run-latest.json")


forge script script/nft/NFT.s.sol:NFTScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

DESTINATION_NFT_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "MockERC721") | .contractAddress
' "./broadcast/NFT.s.sol/$DESTINATION_CHAIN_ID/run-latest.json")


echo "NFT contract successfully deployed and configured on the source chain $SOURCE_NFT_ADDRESS"
echo "NFT contract successfully deployed and configured on the destination chain $DESTINATION_NFT_ADDRESS"
