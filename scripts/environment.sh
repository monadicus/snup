#!/bin/bash

# Set environment variables
export SNARKOS_PATH="/path/to/snarkos"
export NETWORK_NODE_URL="http://your.network.node.url"

# Verify that all environment variables are set
if [ -z "$SNARKOS_PATH" ]; then
    echo "Error: SNARKOS_PATH is not set."
    exit 1
fi

if [ -z "$NETWORK_NODE_URL" ]; then
    echo "Error: NETWORK_NODE_URL is not set."
    exit 1
fi

echo "All required environment variables are set."