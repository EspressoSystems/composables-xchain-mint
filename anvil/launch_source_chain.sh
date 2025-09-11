#!/usr/bin/env bash
set -euo pipefail

source .hyperlane_env
# rm ./hyperlane/chains/source/state.json
# anvil --port $RPC_SOURCE_CHAIN_PORT --chain-id $SOURCE_CHAIN_ID --dump-state ./hyperlane/chains/source/state.json --block-time 2 --mixed-mining
anvil --port $RPC_SOURCE_CHAIN_PORT --chain-id $SOURCE_CHAIN_ID --load-state ./hyperlane/chains/source/state.json --block-time 2 --mixed-mining