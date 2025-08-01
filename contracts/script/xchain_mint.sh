# Load .env
export $(grep -v '^#' .env | xargs)

export S_ESPRESSO_ESCROW_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspressoEscrow") | .contractAddress
' "./broadcast/EspressoEscrow.s.sol/$S_ORIGIN_CHAIN_ID/run-latest.json")
export D_ESPRESSO_ESCROW_ADDRESS=$(jq -r '
  .transactions[] | select(.contractName == "EspressoEscrow") | .contractAddress
' "./broadcast/EspressoEscrow.s.sol/$D_ORIGIN_CHAIN_ID/run-latest.json")

forge script script/XChainMint.s.sol:XChainMintScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "Sending message to NFT contract $D_ESPRESSO_ESCROW_ADDRESS on destination chain"


# TODO try to execute it - send message between chains.
