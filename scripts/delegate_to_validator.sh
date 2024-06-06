#!/bin/bash

# Source the environment variables
source ./environment.sh

# Check if the correct number of arguments are provided
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <DELEGATOR_PRIVATE_KEY> <DELEGATOR_ADDRESS> <WITHDRAW_ADDRESS> <VALIDATOR_NAME> <VALIDATOR_ADDRESS> <AMOUNT>"
    exit 1
fi

# Assign input arguments to variables
DELEGATOR_PRIVATE_KEY=$1
DELEGATOR_ADDRESS=$2
WITHDRAW_ADDRESS=$3
VALIDATOR_NAME=$4
VALIDATOR_ADDRESS=$5
AMOUNT=$6
CLEAN_AMOUNT=$(echo $AMOUNT | sed 's/u64//')

# Make a director to hold funding log files.
mkdir -p ./delegations
LOG=./delegations/${VALIDATOR_NAME}_delegations.log

# Check the balance of the Delegator's account
log "Checking the balance of the Delegator's account..." $LOG
delegator_balance=$(get_balance $DELEGATOR_ADDRESS)

# Check the balance of the Delegator's withdraw account
log "Checking the balance of the Delegator's account..." $LOG
withdraw_balance=$(get_balance $WITHDRAW_ADDRESS)

# Check the balance of the Delegator's withdraw account
log "Checking the balance of the Validator's account pre-delegation..." $LOG
validator_balance=$(get_balance $VALIDATOR_ADDRESS)

log "Delegator's account balance: ${delegator_balance:-0}" $LOG
log "Withdraw account balance: ${withrdraw_balance:-0}" $LOG
log "Validator's account balance: ${validator_balance::-0}" $LOG


# If the balance is null or less than the amount to fund, exit with an error
if [ -z "$delegator_balance" ] || [ "$(echo "$delegator_balance < $CLEAN_AMOUNT" | bc)" -eq 1 ]; then
    log "Error: Insufficient funds in the Delegator's account." $LOG
    exit 1
fi
log "Sufficient funds available in the Delegators's account." $LOG

# Execute the fund delegator command
log "Delegating:  Executing the bond_public command..." $LOG
$SNARKOS_BIN developer execute credits.aleo bond_public \
    --private-key "$DELEGATOR_PRIVATE_KEY" \
    --query "$NETWORK_NODE_URL" \
    --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
    --network 2 \
    "$VALIDATOR_ADDRESS" "$WITHDRAW_ADDRESS" "$AMOUNT"
bond_status=$?
if [ $bond_status -eq 0 ]; then
    log "Completed bond_pubic of $AMOUNT for $VALIDATOR_ADDRESS with withdraw address $WITHDRAW_ADDRESS" $LOG
else 
    log "FAILED:  bond_pubic execute failed." $LOG
    exit 1
fi

validator_address_balance=$(get_balance $VALIDATOR_ADDRESS)

log "TYPE        | ADDRESS                                                         | BALANCE " $LOG
log "--------------------------------------------------------------------------------------------------------" $LOG
log " DELEGATOR  | $DELEGATOR_ADDRESS | $delegator_balance " $LOG
log " WITHDRAW   | $WITHDRAW_ADDRESS | $withdraw_address_balance " $LOG 
log " VALIDATOR  | $VALIDATOR_ADDRESS | $validator_address_balance " $LOG 