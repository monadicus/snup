#!/bin/bash

# Source the environment variables
echo "Sourcing environment variables from environment.sh..."
source ./environment.sh
echo "Environment variables sourced."

# Check if the correct number of arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <FOUNDATION_PRIVATE_KEY> <FOUNDATION_ADDRESS> <VALIDATOR_NAME> <AMOUNT>"
    exit 1
fi

# Assign input arguments to variables
FOUNDATION_PRIVATE_KEY=$1
FOUNDATION_ADDRESS=$2
VALIDATOR_NAME=$3
AMOUNT=$4
CLEAN_AMOUNT=$(echo $AMOUNT | sed 's/u64//')

# Make a director to hold funding log files.
mkdir -p ./fundings
LOG=./fundings/${VALIDATOR_NAME}_funding.log

# Generate a new address using the snarkOS binary
log "Generating a new address using the snarkOS binary..." $LOG
new_account_output=$($SNARKOS_BIN account new)
log "New address generated." $LOG

# Extract the new private key, view key, and address from the output
log "Extracting the new private key, view key, and address from the output..." $LOG
NEW_PRIVATE_KEY=$(echo "$new_account_output" | grep 'Private Key' | awk '{print $3}')
NEW_VIEW_KEY=$(echo "$new_account_output" | grep 'View Key' | awk '{print $3}')
DELEGATOR_ADDRESS=$(echo "$new_account_output" | grep 'Address' | awk '{print $2}')
log "New private key, view key, and address extracted." $LOG

# Print the new account details
log "Generated new account:" $LOG
log "  New Delegator Private Key: $NEW_PRIVATE_KEY" $LOG
log "  New Delegator View Key: $NEW_VIEW_KEY" $LOG
log "  New Delegator Address: $DELEGATOR_ADDRESS" $LOG

# Check the balance of the Foundation's account
log "Checking the balance of the Foundation's account..." $LOG
foundation_balance_response=$(curl -s ${NETWORK_NODE_URL}/canary/program/credits.aleo/mapping/account/${FOUNDATION_ADDRESS})
foundation_balance=$(echo $foundation_balance_response | sed 's/"//g' | sed 's/u64//')

log "Foundation's account balance: ${foundation_balance:-0}" $LOG
log "Foundation's account balance checked." $LOG

# If the balance is null or less than the amount to fund, exit with an error
log "Verifying if the Foundation's account has sufficient funds..." $LOG
if [ -z "$foundation_balance" ] || [ "$(echo "$foundation_balance < $CLEAN_AMOUNT" | bc)" -eq 1 ]; then
    log "Error: Insufficient funds in the Foundation's account." $LOG
    exit 1
fi
log "Sufficient funds available in the Foundation's account." $LOG

# Generate a second set of private key, view key, and address
log "Generating a second set of private key, view key, and address using the snarkOS binary..." $LOG
new_withdraw_account_output=$($SNARKOS_BIN account new)
log "Second set of private key, view key, and address generated." $LOG

# Extract the new private key, view key, and address from the output
log "Extracting the new private key, view key, and address from the output..." $LOG
DELEGATOR_WITHDRAW_PRIVATE_KEY=$(echo "$new_withdraw_account_output" | grep 'Private Key' | awk '{print $3}')
DELEGATOR_WITHDRAW_VIEW_KEY=$(echo "$new_withdraw_account_output" | grep 'View Key' | awk '{print $3}')
DELEGATOR_WITHDRAW_ADDRESS=$(echo "$new_withdraw_account_output" | grep 'Address' | awk '{print $2}')
log "Second set of private key, view key, and address extracted." $LOG

# Print the second set of account details
log "Generated second account:" $LOG
log "  Delegator Withdraw Private Key: $DELEGATOR_WITHDRAW_PRIVATE_KEY" $LOG
log "  Delegator Withdraw View Key: $DELEGATOR_WITHDRAW_VIEW_KEY" $LOG
log "  Delegator Withdraw Address: $DELEGATOR_WITHDRAW_ADDRESS" $LOG

# Transfer the amount to the new DELEGATOR_ADDRESS
log "Transferring $AMOUNT to the new delegator address..." $LOG
$SNARKOS_BIN developer execute credits.aleo transfer_public \
 --private-key "$FOUNDATION_PRIVATE_KEY" \
 --query "$NETWORK_NODE_URL" \
 --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
 --network 2 \
 "$DELEGATOR_ADDRESS" "$AMOUNT"
log "Transfer initiated." $LOG
log "Transfered $AMOUNT to Delegator address $DELEGATOR_ADDRESS." $LOG


# Wait for the transfer to complete by checking the balance of the DELEGATOR_ADDRESS
log "Waiting for the transfer to complete..." $LOG
sleep 8
while true; do
    delegator_balance_response=$(curl -s ${NETWORK_NODE_URL}/canary/program/credits.aleo/mapping/account/${DELEGATOR_ADDRESS})
    delegator_balance=$(echo $delegator_balance_response | sed 's/"//g' | sed 's/u64//')
    log "Delegator's account balance: ${delegator_balance:-0}" $LOG
    
    if [ -n "$delegator_balance" ] && [ "$(echo "$delegator_balance >= $CLEAN_AMOUNT" | bc)" -eq 1 ]; then
        log "Transfer completed. Delegator balance: $delegator_balance" $LOG
        log "Confirmed balance of $delegator_balance in Delegator address $DELEGATOR_ADDRESS." $LOG
        break
    fi
    
    log "Transfer not completed yet. Current balance: ${delegator_balance:-0}. Checking again in 5 seconds..." $LOG
    sleep 5
done

# Execute the fund delegator command
log "Executing the fund delegator command..." $LOG
$SNARKOS_BIN developer execute credits.aleo bond_public \
 --private-key "$FOUNDATION_PRIVATE_KEY" \
 --query "$NETWORK_NODE_URL" \
 --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
 --network 2 \
 "$DELEGATOR_ADDRESS" "$DELEGATOR_WITHDRAW_ADDRESS" "$AMOUNT"
log "Fund delegator command executed." $LOG
log "Completed bond_pubic of $AMOUNT for $DELEGATOR_ADDRESS with withdraw address $DELEGATOR_WITHDRAW_ADDRESS." $LOG