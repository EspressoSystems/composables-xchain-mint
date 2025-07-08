#!/usr/bin/env bash
set -e

# Load .env
export $(grep -v '^#' .env | xargs)

envsubst < ./config/agent-example.json > ./config/agent.json

echo "hyperlane config agent.json created. check ./config/agent.json"

envsubst < ./config/key-policy-example.json > ./config/key-policy.json

echo "AWS Signer key policy generated. check ./config/key-policy.json"

envsubst < ./config/bucket-policy-example.json > ./config/bucket-policy.json

echo "AWS bucket policy generated. check ./config/bucket-policy.json"