docker run \
  -it \
  -p 9090:9090 \
  -e CONFIG_FILES=/config/agent-config.json \
  --mount type=bind,source=./configs/agent-config.json,target=/config/agent-config.json,readonly \
  --mount type=bind,source="$(pwd)"/hyperlane_db_relayer,target=/hyperlane_db \
  --mount type=bind,source="$(pwd)"/$VALIDATOR_SIGNATURES_DIR,target=/tmp/validator-signatures,readonly \
  gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.4.0 \
  ./relayer \
  --db /hyperlane_db \
  --relayChains anvil,rari \
  --allowLocalCheckpointSyncers true \
  --defaultSigner.key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \