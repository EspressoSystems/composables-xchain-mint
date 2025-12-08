#!/usr/bin/env bash
set -eo pipefail

APE_PORT=8545
RARI_PORT=8546
SENDER=0xb62b607FFAEb8dB7DE9FAD002656fd7B394e9168

cleanup() {
    echo "Stopping anvil forks..."
    kill $APE_PID $RARI_PID 2>/dev/null || true
}
trap cleanup EXIT

echo "=== Starting Anvil Forks ==="

anvil --fork-url https://apechain.mainnet.on.espresso.network --port $APE_PORT > /dev/null 2>&1 &
APE_PID=$!

anvil --fork-url https://rari.mainnet.on.espresso.network --port $RARI_PORT > /dev/null 2>&1 &
RARI_PID=$!

sleep 3

# Impersonate sender on both forks
cast rpc anvil_impersonateAccount $SENDER --rpc-url http://localhost:$APE_PORT
cast rpc anvil_impersonateAccount $SENDER --rpc-url http://localhost:$RARI_PORT

echo ""
echo "=== Running FixApechain ==="
forge script script/prod/FixApechain.s.sol \
  --via-ir \
  --rpc-url http://localhost:$APE_PORT \
  --broadcast \
  --unlocked \
  --sender $SENDER \
  --skip-simulation \
  -vvv

echo ""
echo "=== Running FixRarichain ==="
forge script script/prod/FixRarichain.s.sol \
  --via-ir \
  --rpc-url http://localhost:$RARI_PORT \
  --broadcast \
  --unlocked \
  --sender $SENDER \
  --skip-simulation \
  -vvv

echo ""
echo "=== Running verify-deployment.sh ==="
APE_RPC=http://localhost:$APE_PORT RARI_RPC=http://localhost:$RARI_PORT ./script/verify-deployment.sh
