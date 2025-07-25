# Load .env
export $(grep -v '^#' .env | xargs)

export S_ESPRESSO_ESCROW_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspressoEscrow") | .contractAddress
' "./broadcast/EspressoEscrow.s.sol/$S_ORIGIN_CHAIN_ID/run-latest.json")
export D_ESPRESSO_ESCROW_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspressoEscrow") | .contractAddress
' "./broadcast/EspressoEscrow.s.sol/$D_ORIGIN_CHAIN_ID/run-latest.json")

cast send $S_ESPRESSO_ESCROW_ADDRESS "xChainMint(uint32,address)" $D_DESTINATION_CHAIN_ID $D_ESPRESSO_ESCROW_ADDRESS --private-key $DEPLOYER_PRIVATE_KEY --rpc-url=$SOURCE_CHAIN_RPC_URL
echo "Sending message to NFT contract $D_ESPRESSO_ESCROW_ADDRESS on destination chain"
