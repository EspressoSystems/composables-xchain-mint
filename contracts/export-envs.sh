#!/usr/bin/env bash
set -e

# Load .env
export $(grep -v '^#' .env | xargs)