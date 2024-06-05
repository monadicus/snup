#!/bin/bash

# Set environment variables
# This is the path to the snarkOS binary.
# Assumes you've checked out the snarkOS repo and built the binary
# in a directory called `snarkOS` in a directory parallel to this repository.
export SNARKOS_BIN="../../snarkOS/target/release/snarkos"
# This uses MONADIC.US's public canary network node.
# You can replace this with your own network node URL or use it if you like.
#export NETWORK_NODE_URL="http://99.48.167.129:3030"
export NETWORK_NODE_URL="http://localhost:3030"

# Function to print log with timestamp
log() {
    local message=$1
    local logfile=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$logfile"
}

# Verify that all environment variables are set
if [ -z "$SNARKOS_BIN" ]; then
    echo "Error: SNARKOS_BIN is not set."
    exit 1
fi

if [ -z "$NETWORK_NODE_URL" ]; then
    echo "Error: NETWORK_NODE_URL is not set."
    exit 1
fi

# Check if snarkOS binary exists and is executable
if [ ! -x "$SNARKOS_BIN" ]; then
    echo "Error: snarkOS binary does not exist or is not executable at $SNARKOS_BIN."
    exit 1
fi

# Check the validity of the NETWORK_NODE_URL by performing a curl request
response=$(curl -s ${NETWORK_NODE_URL}/canary/block/0)

# Check if the response contains a block_hash
if echo "$response" | grep -q '"block_hash"'; then
    echo "NETWORK_NODE_URL is valid and responded with a block_hash."
else
    echo "Error: NETWORK_NODE_URL is not valid or did not respond correctly."
    exit 1
fi

echo "All required environment variables are set and snarkOS binary is verified."
