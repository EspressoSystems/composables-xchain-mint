#!/usr/bin/env bash
set -e

# Load .env
export $(grep -v '^#' .env | xargs)

envsubst < ./config/agent-example.json > ./config/agent.json