#!/bin/bash

# Source the environment variables
source ./environment.sh

# Check if the correct number of arguments are provided
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <PRIVATE_KEY> <VALIDATOR_ADDRESS> <WITHDRAW_ADDRESS> <AMOUNT> <COMMISSION> <NAME>"
    exit 1
fi

# Assign input arguments to variables
PRIVATE_KEY=$1
VALIDATOR_ADDRESS=$2
WITHDRAW_ADDRESS=$3
AMOUNT=$4
COMMISSION=$5
NAME=$6

TX_ID="TX_ID"

bond_validator $PRIVATE_KEY $VALIDATOR_ADDRESS $WITHDRAW_ADDRESS $AMOUNT $COMMISSION $NAME $TX_ID
# Execute the command