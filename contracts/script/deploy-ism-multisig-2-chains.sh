# Load .env
export $(grep -v '^#' .env | xargs)

forge script script/DeployAndUpdateISMMultisig.s.sol:DeployAndUpdateISMMultisigScript  --rpc-url $SOURCE_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir
forge script script/DeployAndUpdateISMMultisig.s.sol:DeployAndUpdateISMMultisigScript  --rpc-url $DESTINATION_CHAIN_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --via-ir

echo "StaticMessageIdMultisigIsm contract successfully deployed and configured on the source chain"
echo "StaticMessageIdMultisigIsm contract successfully deployed and configured on the destination chain"