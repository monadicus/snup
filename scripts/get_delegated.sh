#!/bin/bash

# Source the environment variables
source ./environment.sh

# Check if the correct number of arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ADDRESS>"
    exit 1
fi

ADDRESS=$1

echo $(get_delegated $ADDRESS)