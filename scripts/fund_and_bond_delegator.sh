#!/bin/bash

# Source the environment variables
source ./environment.sh

# Check if the correct number of arguments are provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <FOUNDATION_PRIVATE_KEY> <FOUNDATION_ADDRESS> <VALIDATOR_NAME> <AMOUNT> <FEES>"
    exit 1
fi

# Assign input arguments to variables
FOUNDATION_PRIVATE_KEY=$1
FOUNDATION_ADDRESS=$2
VALIDATOR_NAME=$3
AMOUNT=$4
FEES=$5
CLEAN_AMOUNT=$(echo $AMOUNT | sed 's/u64//')
CLEAN_FEES=$(echo $FEES | sed 's/u64//')

LOG=./fundings/${VALIDATOR_NAME}_funding.log

log "  " $LOG
log "  " $LOG
log " BEGIN New Funding of Delegator for $VALIDATOR_NAME  " $LOG
log "  " $LOG
# Generate a new address using the snarkOS binary
log "Generating a new delegate address..." $LOG
new_account_output=$($SNARKOS_BIN account new)
log "New delegate address generated." $LOG
log "  " $LOG
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

log "Saving the new delegate key to ./accounts/${VALIDATOR_NAME}_delegate.key..." $LOG
save_account ${VALIDATOR_NAME}_delegate $NEW_PRIVATE_KEY $NEW_VIEW_KEY $DELEGATOR_ADDRESS

# Check the balance of the Foundation's account
log "Checking the balance of the Foundation's account..." $LOG
foundation_balance_response=$(curl -s ${NETWORK_NODE_URL}/canary/program/credits.aleo/mapping/account/${FOUNDATION_ADDRESS})
foundation_balance=$(echo $foundation_balance_response | sed 's/"//g' | sed 's/u64//')

log "Foundation's account balance: ${foundation_balance:-0}" $LOG

# If the balance is null or less than the amount to fund, exit with an error
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
DELEGATOR_WITHDRAW_PRIVATE_KEY=$(echo "$new_withdraw_account_output" | grep 'Private Key' | awk '{print $3}')
DELEGATOR_WITHDRAW_VIEW_KEY=$(echo "$new_withdraw_account_output" | grep 'View Key' | awk '{print $3}')
DELEGATOR_WITHDRAW_ADDRESS=$(echo "$new_withdraw_account_output" | grep 'Address' | awk '{print $2}')

# Print the second set of account details
log "Generated withdraw account:" $LOG
log "  Delegator Withdraw Private Key: $DELEGATOR_WITHDRAW_PRIVATE_KEY" $LOG
log "  Delegator Withdraw View Key: $DELEGATOR_WITHDRAW_VIEW_KEY" $LOG
log "  Delegator Withdraw Address: $DELEGATOR_WITHDRAW_ADDRESS" $LOG

log "Saving the new delegate withdrawal key to ./accounts/${VALIDATOR_NAME}_delegate_withdraw.key..." $LOG
save_account "${VALIDATOR_NAME}_delegate_withdraw" $DELEGATOR_WITHDRAW_PRIVATE_KEY $DELEGATOR_WITHDRAW_VIEW_KEY $DELEGATOR_WITHDRAW_ADDRESS

# Transfer the amount to the new DELEGATOR_ADDRESS
log "Transferring $AMOUNT to the new delegator address..." $LOG
funding_tx_id=""
transfer_public $FOUNDATION_PRIVATE_KEY $DELEGATOR_ADDRESS $AMOUNT ${VALIDATOR_NAME}_delegator "funding_tx_id"
log "Transfered $AMOUNT to Delegator address $DELEGATOR_ADDRESS." $LOG

#$SNARKOS_BIN developer execute credits.aleo transfer_public \
# --private-key "$FOUNDATION_PRIVATE_KEY" \
# --query "$NETWORK_NODE_URL" \
# --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
# --network 2 \
# "$DELEGATOR_ADDRESS" "$AMOUNT"
#transfer_status=$?
#
#if [ $transfer_status -eq 0 ]; then
#    log "Transfered $AMOUNT to Delegator address $DELEGATOR_ADDRESS." $LOG
#else
#    log "FAILED:  Transfered $AMOUNT to Delegator address $DELEGATOR_ADDRESS." $LOG
#    exit 1
#fi

# Transfer additional credits to cover fees to the new DELEGATOR_ADDRESS
log "Transferring $FEES to the new delegator address..." $LOG
fee_tx_id=""
transfer_public $FOUNDATION_PRIVATE_KEY $DELEGATOR_ADDRESS $FEES ${VALIDATOR_NAME}_delegator "fee_tx_id"
log "Transfered additional $FEES to Delegator address $DELEGATOR_ADDRESS." $LOG
#$SNARKOS_BIN developer execute credits.aleo transfer_public \
# --private-key "$FOUNDATION_PRIVATE_KEY" \
# --query "$NETWORK_NODE_URL" \
# --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
# --network 2 \
# "$DELEGATOR_ADDRESS" "$FEES"
#transfer_status=$?

#if [ $transfer_status -eq 0 ]; then 
#    log "Transfered additional $FEES to Delegator address $DELEGATOR_ADDRESS." $LOG
#else
#    log "FAILED:  Transfered additional $FEES to Delegator address $DELEGATOR_ADDRESS." $LOG
#    exit 1
#fi

# Transfer additional credits to DELEGATOR_WITHDRAWAL_ADDRESS
log "Transferring $FEES to the new delegator withdrawal address..." $LOG
withdraw_fee_tx_id=""
transfer_public $FOUNDATION_PRIVATE_KEY $DELEGATOR_WITHDRAW_ADDRESS $FEES ${VALIDATOR_NAME}_delegator_withdraw "withdraw_fee_tx_id"
log "Transfered additional $FEES to delegator withdrawal address $DELEGATOR_WITHDRAW_ADDRESS" $LOG
#$SNARKOS_BIN developer execute credits.aleo transfer_public \
#    --private-key "$FOUNDATION_PRIVATE_KEY" \
#    --query "$NETWORK_NODE_URL" \
#    --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
#    --network 2 \
#    "$DELEGATOR_WITHDRAW_ADDRESS" "$FEES"
#transfer_status=$?

#if [ $transfer_status -eq 0 ]; then
#    log "Transfered additional $FEES to delegator withdrawal address $DELEGATOR_WITHDRAW_ADDRESS" $LOG
#else
#    log "FAILED:  Transfer of additional $FEES to delegator withdrawal address $DELEGATOR_WITHDRAW_ADDRESS" $LOG
#    exit 1
#fi 


# Wait for the transfer to complete by checking the balance of the DELEGATOR_ADDRESS
#log "Waiting for the transfer to complete..." $LOG
#while true; do
#    delegator_balance_response=$(curl -s ${NETWORK_NODE_URL}/canary/program/credits.aleo/mapping/account/${DELEGATOR_ADDRESS})
#    delegator_balance=$(echo $delegator_balance_response | sed 's/"//g' | sed 's/u64//')
#    # log "Delegator's account balance: ${delegator_balance:-0}" $LOG
#    
#    if [ -n "$delegator_balance" ] && [ "$(echo "$delegator_balance >= $CLEAN_AMOUNT" | bc)" -eq 1 ]; then
#        log "Confirmed balance of $delegator_balance in Delegator address $DELEGATOR_ADDRESS" $LOG
#        break
#    fi
#    
    # log "Transfer not completed yet. Current balance: ${delegator_balance:-0}. Checking again in 3 seconds..." $LOG
#    sleep 1
#done

#log "Waiting for the delegator withdraw fee transfer to complete..." $LOG
#while true; do
#    delegator_withdraw_address_balance=$(get_balance $DELEGATOR_WITHDRAW_ADDRESS)
#    if [ -n "$delegator_withdraw_address_balance" ] && [ "$(echo "$delegator_withdraw_address_balance >= $CLEAN_FEES" | bc)" -eq 1 ]; then
#        log "Confirmed balance of $delegator_withdraw_address_balance in withdraw address $DELEGATOR_WITHDRAW_ADDRESS" $LOG
#        break
#    fi
#    sleep 1
#done

delegator_balance=$(get_balance $DELEGATOR_ADDRESS)
delegator_withdraw_address_balance=$(get_balance $DELEGATOR_WITHDRAW_ADDRESS)


# Execute the fund delegator command
log "Executing the bond_public command..." $LOG
$SNARKOS_BIN developer execute credits.aleo bond_public \
    --private-key "$FOUNDATION_PRIVATE_KEY" \
    --query "$NETWORK_NODE_URL" \
    --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
    --network 2 \
    "$DELEGATOR_ADDRESS" "$DELEGATOR_WITHDRAW_ADDRESS" "$AMOUNT"
bond_status=$?
if [ $bond_status -eq 0 ]; then
    log "Completed bond_pubic of $AMOUNT for $DELEGATOR_ADDRESS with withdraw address $DELEGATOR_WITHDRAW_ADDRESS" $LOG
else 
    log "FAILED:  bond_pubic of $AMOUNT for $DELEGATOR_ADDRESS with withdraw address $DELEGATOR_WITHDRAW_ADDRESS" $LOG
    exit 1
fi

log " " $LOG
log "IMPORTANT!   Do not lose the key files in ./accounts!  Back them up. " $LOG
log " " $LOG
log "TYPE                | VALUE                                                               | BALANCE " $LOG
log "---------------------------------------------------------------------------------------------------------------" $LOG
log " ANF                | $FOUNDATION_ADDRESS | $foundation_balance " $LOG
log " Delegator Address  | $DELEGATOR_ADDRESS | $delegator_balance " $LOG 
log " Withdraw Address   | $DELEGATOR_WITHDRAW_ADDRESS | $delegator_withdraw_address_balance " $LOG 
log "---------------------------------------------------------------------------------------------------------------" $LOG
log "          ANF Private Key:  $FOUNDATION_PRIVATE_KEY " $LOG
log "    Delegator Private Key:  $NEW_PRIVATE_KEY " $LOG
log "     Withdraw Private Key:  $DELEGATOR_WITHDRAW_PRIVATE_KEY " $LOG
log "---------------------------------------------------------------------------------------------------------------" $LOG
log " Transactions generated and logged: " $LOG
log "        Funding Transaction: $funding_tx_id " $LOG
log "            Fee Transaction: $fee_tx_id " $LOG
log "   Withdraw Fee Transaction: $withdraw_fee_tx_id " $LOG
log " " $LOG
log "             Delegator Key in: ./accounts/${VALIDATOR_NAME}_delegate.key" $LOG
log "    Delegator Withdraw Key in: ./accounts/${VALIDATOR_NAME}_delegate_withdraw.key" $LOG
log " " $LOG
log "    Funded $delegator_balance to be delegated to:  ${VALIDATOR_NAME}." $LOG
log " " $LOG
log "  To execute delegation: ./delegate_to_validator.sh using above values.  " $LOG
log " " $LOG
log " Godspeed." $LOG 