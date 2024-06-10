#!/bin/bash

# Source the environment variables
source ./environment.sh

# Check if the correct number of arguments are provided
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <FUNDING_PRIVATE_KEY> <FUNDING_ADDRESS> <VALIDATOR_ADDRESS> <VALIDATOR_NAME> <AMOUNT> <FEES>"
    exit 1
fi

# Assign input arguments to variables
FUNDING_PRIVATE_KEY=$1
FUNDING_ADDRESS=$2
VALIDATOR_ADDRESS=$3
VALIDATOR_NAME=$4
AMOUNT=$5
FEES=$6
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
DELEGATOR_PRIVATE_KEY=$(echo "$new_account_output" | grep 'Private Key' | awk '{print $3}')
DELEGATOR_VIEW_KEY=$(echo "$new_account_output" | grep 'View Key' | awk '{print $3}')
DELEGATOR_ADDRESS=$(echo "$new_account_output" | grep 'Address' | awk '{print $2}')
log "New private key, view key, and address extracted." $LOG

# Print the new account details
log "Generated new account:" $LOG
log "  New Delegator Private Key: $DELEGATOR_PRIVATE_KEY" $LOG
log "  New Delegator View Key: $DELEGATOR_VIEW_KEY" $LOG
log "  New Delegator Address: $DELEGATOR_ADDRESS" $LOG

log "Saving the new delegate key to ./accounts/${VALIDATOR_NAME}_delegate.key..." $LOG
save_account ${VALIDATOR_NAME}_delegate $DELEGATOR_PRIVATE_KEY $DELEGATOR_VIEW_KEY $DELEGATOR_ADDRESS

# Check the balance of the funding's account
log "Checking the balance of the funders's account..." $LOG
funding_balance_response=$(curl -s ${NETWORK_NODE_URL}/canary/program/credits.aleo/mapping/account/${FUNDING_ADDRESS})
funding_balance=$(echo $funding_balance_response | sed 's/"//g' | sed 's/u64//')

log "Funder's account balance: $(to_credits ${funding_balance:-0})" $LOG

# If the balance is null or less than the amount to fund, exit with an error
if [ -z "$funding_balance" ] || [ "$(echo "$funding_balance < $CLEAN_AMOUNT" | bc)" -eq 1 ]; then
    log "Error: Insufficient funds in the funding's account." $LOG
    exit 1
fi
log "Sufficient funds available in the funding's account." $LOG

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
log "Transferring $(to_credits $AMOUNT) ($AMOUNT) to the new delegator address..." $LOG
funding_tx_id=""
transfer_public $FUNDING_PRIVATE_KEY $DELEGATOR_ADDRESS $AMOUNT ${VALIDATOR_NAME}_delegator "funding_tx_id"
log "Transfered $(to_credits $AMOUNT) ($AMOUNT) to Delegator address $DELEGATOR_ADDRESS." $LOG


# Transfer additional credits to cover fees to the new DELEGATOR_ADDRESS
log "Transferring $(to_credits $FEES) ($FEES) to the new delegator address..." $LOG
fee_tx_id=""
transfer_public $FUNDING_PRIVATE_KEY $DELEGATOR_ADDRESS $FEES ${VALIDATOR_NAME}_delegator "fee_tx_id"
log "Transfered additional $(to_credits $FEES) ($FEES) to Delegator address $DELEGATOR_ADDRESS." $LOG

log "Transferring $(to_credits $FEES)($FEES) to the new delegator withdrawal address..." $LOG
withdraw_fee_tx_id=""
transfer_public $FUNDING_PRIVATE_KEY $DELEGATOR_WITHDRAW_ADDRESS $FEES ${VALIDATOR_NAME}_delegator_withdraw "withdraw_fee_tx_id"
log "Transfered additional $(to_credits $FEES) ($FEES) to delegator withdrawal address $DELEGATOR_WITHDRAW_ADDRESS" $LOG

delegator_balance=$(get_balance $DELEGATOR_ADDRESS)
delegator_withdraw_address_balance=$(get_balance $DELEGATOR_WITHDRAW_ADDRESS)

# Execute the fund delegator command
log "Executing the bond_public command..." $LOG

bond_public_tx_id="bond_public_tx_id"

bond_public $DELEGATOR_PRIVATE_KEY $DELEGATOR_ADDRESS $VALIDATOR_ADDRESS $DELEGATOR_WITHDRAW_ADDRESS $AMOUNT $VALIDATOR_NAME $bond_public_tx_id

log " " $LOG
log "IMPORTANT!   Do not lose the key files in ./accounts!  Back them up. " $LOG
log " " $LOG
log "TYPE                | VALUE                                                               | BALANCE " $LOG
log "---------------------------------------------------------------------------------------------------------------" $LOG
log " Funding Address    | $FUNDING_ADDRESS | $(to_credits $funding_balance) ($funding_balance) " $LOG
log " Delegator Address  | $DELEGATOR_ADDRESS | $(to_credits $delegator_balance) ($delegator_balance) " $LOG 
log " Withdraw Address   | $DELEGATOR_WITHDRAW_ADDRESS | $(to_credits $delegator_withdraw_address_balance) ($delegator_withdraw_address_balance) " $LOG 
log "---------------------------------------------------------------------------------------------------------------" $LOG
log "      Funding Private Key:  $FUNDING_PRIVATE_KEY " $LOG
log "    Delegator Private Key:  $DELEGATOR_PRIVATE_KEY " $LOG
log "     Withdraw Private Key:  $DELEGATOR_WITHDRAW_PRIVATE_KEY " $LOG
log "---------------------------------------------------------------------------------------------------------------" $LOG
log " Transactions generated and logged: " $LOG
log "        Funding Transaction: $funding_tx_id " $LOG
log "            Fee Transaction: $fee_tx_id " $LOG
log "   Withdraw Fee Transaction: $withdraw_fee_tx_id " $LOG
log "    bond_public Transaction: $bond_public_tx_id " $LOG
log " " $LOG
log "             Delegator Key in: ./accounts/${VALIDATOR_NAME}_delegate.key" $LOG
log "    Delegator Withdraw Key in: ./accounts/${VALIDATOR_NAME}_delegate_withdraw.key" $LOG
log " " $LOG
log "    Delegated $(to_credits $AMOUNT) to:  ${VALIDATOR_NAME}" $LOG
log "        Validator Address: ${VALIDATOR_ADDRESS}" $LOG
log " " $LOG
log " Godspeed." $LOG 