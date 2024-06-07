#!/bin/bash

# Source the environment variables
source ./environment.sh

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "$#"
    echo "Usage: $0 <MAPPING> <ADDRESS>"
    exit 1
fi

echo "$(get_mapping $1 $2)"