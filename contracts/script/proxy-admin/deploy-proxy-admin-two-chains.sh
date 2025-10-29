# <ai_context>
# This script deploys ProxyAdmin on two chains using CREATE3 and checks addresses match.
# </ai_context>
#!/usr/bin/env bash
set -euxo pipefail
# Load .env
export $(grep -v '^#' ./.env | xargs)
SALT="proxy_admin_salt_v5_2_0"
SALT_HASH=$(cast keccak $SALT)
PROXY_ADMIN_ADDRESS=$(cast call $CREATE3_FACTORY_ADDRESS "getDeployed(address,bytes32)(address)" $DEPLOYER_ADDRESS $SALT_HASH --rpc-url $SOURCE_CHAIN_RPC_URL)
echo "Predicted proxy admin address: $PROXY_ADMIN_ADDRESS"
export SALT=$SALT
export OWNER=$DEPLOYER_ADDRESS
forge script script/token/DeployProxyAdmin.s.sol:DeployProxyAdminScript --rpc-url $SOURCE_CHAIN_RPC_URL --ledger --broadcast --via-ir
forge script script/token/DeployProxyAdmin.s.sol:DeployProxyAdminScript --rpc-url $DESTINATION_CHAIN_RPC_URL --ledger --broadcast --via-ir
SOURCE_PROXY_ADMIN_ADDRESS=$PROXY_ADMIN_ADDRESS
DESTINATION_PROXY_ADMIN_ADDRESS=$PROXY_ADMIN_ADDRESS
echo "ProxyAdmin deployed on source chain at $SOURCE_PROXY_ADMIN_ADDRESS"
echo "ProxyAdmin deployed on destination chain at $DESTINATION_PROXY_ADMIN_ADDRESS"
if [ "$SOURCE_PROXY_ADMIN_ADDRESS" != "$DESTINATION_PROXY_ADMIN_ADDRESS" ]; then
  echo "Error: ProxyAdmin addresses do not match across chains!"
  exit 1
fi
# Verify owner
SOURCE_OWNER=$(cast call $SOURCE_PROXY_ADMIN_ADDRESS "owner()(address)" --rpc-url $SOURCE_CHAIN_RPC_URL)
if [ "$SOURCE_OWNER" != "$DEPLOYER_ADDRESS" ]; then
  echo "Error: Source ProxyAdmin owner mismatch!"
  exit 1
fi
DEST_OWNER=$(cast call $DESTINATION_PROXY_ADMIN_ADDRESS "owner()(address)" --rpc-url $DESTINATION_CHAIN_RPC_URL)
if [ "$DEST_OWNER" != "$DEPLOYER_ADDRESS" ]; then
  echo "Error: Destination ProxyAdmin owner mismatch!"
  exit 1
fi
echo "Add to .env:"
echo "SOURCE_PROXY_ADMIN_ADDRESS=$SOURCE_PROXY_ADMIN_ADDRESS"
echo "DESTINATION_PROXY_ADMIN_ADDRESS=$DESTINATION_PROXY_ADMIN_ADDRESS"