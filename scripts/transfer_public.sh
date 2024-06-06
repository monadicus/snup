#!/bin/bash

# Source the environment variables
source ./environment.sh

# Check if the correct number of arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <FROM_PRIVATE_KEY> <TO_ADDRESS> <AMOUNT> <TO_NAME>"
    exit 1
fi

PRIVATE_KEY=$1
TO_ADDRESS=$2
AMOUNT=$3
NAME=$4

transfer_public $PRIVATE_KEY $TO_ADDRESS $AMOUNT "./transfers/${NAME}_transfer.log"
