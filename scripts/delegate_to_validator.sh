#!/bin/bash

# Source the environment variables
source ./environment.sh

# Check if the correct number of arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <DELEGATOR_PRIVATE_KEY> <VALIDATOR_ADDRESS> <DELEGATOR_WITHDRAWAL_ADDRESS> <AMOUNT>"
    exit 1
fi

# Assign input arguments to variables
DELEGATOR_PRIVATE_KEY=$1
VALIDATOR_ADDRESS=$2
DELEGATOR_WITHDRAWAL_ADDRESS=$3
AMOUNT=$4

# Execute the command
$SNARKOS_PATH developer execute credits.aleo bond_public \
 --private-key "$DELEGATOR_PRIVATE_KEY" \
 --query "$NETWORK_NODE_URL" \
 --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
 --network 2 \
 "$VALIDATOR_ADDRESS" "$DELEGATOR_WITHDRAWAL_ADDRESS" "$AMOUNT"