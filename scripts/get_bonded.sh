#!/bin/bash
# Check if input is provided via stdin

source ./environment.sh

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <ADDRESS>"
  exit 1
fi

ADDRESS=$1
echo $(get_bonded $ADDRESS)