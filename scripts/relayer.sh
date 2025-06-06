docker run \
  -it \
  -e CONFIG_FILES=/config/agent-config.json \
  --mount type=bind,source=./configs/agent-config.json,target=/config/agent-config.json,readonly \
  --mount type=bind,source="$(pwd)"/hyperlane_db_relayer,target=/hyperlane_db \
  --mount type=bind,source="$(pwd)"/$VALIDATOR_SIGNATURES_DIR,target=/tmp/validator-signatures,readonly \
  gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.4.0 \
  ./relayer \
  --db /hyperlane_db \
  --relayChains anvil,rari \
  --allowLocalCheckpointSyncers true \
  --defaultSigner.key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \