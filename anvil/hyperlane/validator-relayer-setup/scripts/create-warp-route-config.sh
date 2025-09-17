#!/usr/bin/env bash
set -e

# Load .env
export $(grep -v '^#' .env | xargs)

# Generate the warp route configuration file for the contracts
envsubst < warp-route-deploy.yaml.example > ../../hyperlane/deployments/warp_routes/ETH/destination-deploy.yaml
echo "Source-Destinastion warp-route-config generated"

