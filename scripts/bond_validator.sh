#!/bin/bash

# Source the environment variables
source ./environment.sh

# Check if the correct number of arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <VALIDATOR_PRIVATE_KEY> <VALIDATOR_WITHDRAWAL_ADDRESS> <AMOUNT> <COMMISSION>"
    exit 1
fi

# Assign input arguments to variables
VALIDATOR_PRIVATE_KEY=$1
VALIDATOR_WITHDRAWAL_ADDRESS=$2
AMOUNT=$3
COMMISSION=$4

# Execute the command
$SNARKOS_PATH/snarkos developer execute credits.aleo bond_validator \
 --private-key "$VALIDATOR_PRIVATE_KEY" \
 --query "$NETWORK_NODE_URL" \
 --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
 --network 2 \
 "$VALIDATOR_WITHDRAWAL_ADDRESS" "$AMOUNT" "$COMMISSION"