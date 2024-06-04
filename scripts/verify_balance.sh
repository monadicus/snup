#!/bin/bash

# Source the environment variables
source ./environment.sh

# Check if the correct number of arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ADDRESS>"
    exit 1
fi

# Assign input argument to variable
ADDRESS=$1

# Check the balance for the provided address
curl ${NETWORK_NODE_URL}/canary/program/credits.aleo/mapping/account/${ADDRESS}