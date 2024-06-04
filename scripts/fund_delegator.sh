#!/bin/bash

# Source the environment variables
source ./environment.sh

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <FOUNDATION_PRIVATE_KEY> <DELEGATOR_ADDRESS> <AMOUNT>"
    exit 1
fi

# Assign input arguments to variables
FOUNDATION_PRIVATE_KEY=$1
DELEGATOR_ADDRESS=$2
AMOUNT=$3

# Execute the command
$SNARKOS_PATH developer execute credits.aleo transfer_public \
 --private-key "$FOUNDATION_PRIVATE_KEY" \
 --query "$NETWORK_NODE_URL" \
 --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
 --network 2 \
 "$DELEGATOR_ADDRESS" "$AMOUNT"