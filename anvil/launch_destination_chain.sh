#!/usr/bin/env bash
set -euo pipefail

source .hyperlane_env
# rm ./hyperlane/chains/destination/state.json
# anvil --port $RPC_DESTINATION_CHAIN_PORT --chain-id $DESTINATION_CHAIN_ID --dump-state ./hyperlane/chains/destination/state.json --block-time 2 --mixed-mining
anvil --port $RPC_DESTINATION_CHAIN_PORT --chain-id $DESTINATION_CHAIN_ID --load-state ./hyperlane/chains/destination/state.json --block-time 2 --mixed-mining
