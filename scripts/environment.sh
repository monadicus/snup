#!/bin/bash

# Set environment variables
# This is the path to the snarkOS binary.
# Assumes you've checked out the snarkOS repo and built the binary
# in a directory called `snarkOS` in a directory parallel to this repository.
export SNARKOS_BIN="../../snarkOS/target/release/snarkos"
# This uses MONADIC.US's public canary network node.
# You can replace this with your own network node URL or use it if you like.
#export NETWORK_NODE_URL="http://99.48.167.129:3030"
export NETWORK_NODE_URL="http://localhost:3030"

# Function to print log with timestamp
log() {
    local message=$1
    local logfile=$2
    local logdir=$(dirname "$logfile")
    # Create the directory if it doesn't exist
    mkdir -p "$logdir"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$logfile"
}

# Verify that all environment variables are set
if [ -z "$SNARKOS_BIN" ]; then
    echo "Error: SNARKOS_BIN is not set."
    exit 1
fi

if [ -z "$NETWORK_NODE_URL" ]; then
    echo "Error: NETWORK_NODE_URL is not set."
    exit 1
fi

# Check if snarkOS binary exists and is executable
if [ ! -x "$SNARKOS_BIN" ]; then
    echo "Error: snarkOS binary does not exist or is not executable at $SNARKOS_BIN."
    exit 1
fi

# Check the validity of the NETWORK_NODE_URL by performing a curl request
response=$(curl -s ${NETWORK_NODE_URL}/canary/block/0)

# Check if the response contains a block_hash
if echo "$response" | grep -q '"block_hash"'; then
    #echo "NETWORK_NODE_URL: ${NETWORK_NODE_URL} is valid and responded with a block_hash."
    :
else
    echo "Error: NETWORK_NODE_URL is not valid or did not respond correctly."
    exit 1
fi

new_account() {
    local NAME=$1
    local new_account_output=$($SNARKOS_BIN account new)
    local account_file="./accounts/${NAME}.key"

    # Extract the new private key, view key, and address from the output
    local NEW_PRIVATE_KEY=$(echo "$new_account_output" | grep 'Private Key' | awk '{print $3}')
    local NEW_VIEW_KEY=$(echo "$new_account_output" | grep 'View Key' | awk '{print $3}')
    local NEW_ADDRESS=$(echo "$new_account_output" | grep 'Address' | awk '{print $2}')
    # Print the new account details
    log "  " $account_file
    log "       TYPE | VALUE:" $account_file
    log "------------------------------------------------------------------------" $account_file
    log " Private Key | $NEW_PRIVATE_KEY" $account_file
    log "    View Key | $NEW_VIEW_KEY" $account_file
    log "     Address | $NEW_ADDRESS" $account_file
}

save_account() {
    local NAME=$1
    local NEW_PRIVATE_KEY=$2
    local NEW_VIEW_KEY=$3
    local NEW_ADDRESS=$4
    local account_file="./accounts/${NAME}.key"
    # Print the new account details
    log "  " $account_file
    log "       TYPE | VALUE:" $account_file
    log "------------------------------------------------------------------------" $account_file
    log " Private Key | $NEW_PRIVATE_KEY" $account_file
    log "    View Key | $NEW_VIEW_KEY" $account_file
    log "     Address | $NEW_ADDRESS" $account_file
}

get_balance() {
    local ADDRESS=$1
    local balance_response=$(curl -s ${NETWORK_NODE_URL}/canary/program/credits.aleo/mapping/account/${ADDRESS})
    echo "$(echo ${balance_response} | sed 's/"//g' | sed 's/u64//')"
}

transfer_public () {
    local PRIVATE_KEY=$1
    local TO_ADDRESS=$2
    local AMT=$3
    local NAME=$4
    local TX_ID=$5
    local transfer_log="./transfers/${NAME}_transfers.log"

    log "   " $transfer_log
    log "   " $transfer_log
    log "BEGIN transfer_public to $NAME " $transfer_log
    log "   " $transfer_log
    local pre_balance_response=$(curl -s ${NETWORK_NODE_URL}/canary/program/credits.aleo/mapping/account/${TO_ADDRESS})
    log "Balance before transfer: $pre_balance_response" $transfer_log
    local clean_amount=$(echo $AMT | sed 's/"//g' | sed 's/u64//')
    local pre_balance=$(echo $pre_balance_response | sed 's/"//g' | sed 's/u64//')
    # Transfer additional credits to DELEGATOR_WITHDRAWAL_ADDRESS
    log "Transferring $AMT  " $transfer_log
    log "  From Private Key:  $PRIVATE_KEY" $transfer_log
    log "        To Address:  $TO_ADDRESS ..." $transfer_log
    log "   " $transfer_log

    local output=$($SNARKOS_BIN developer execute credits.aleo transfer_public \
        --private-key "$PRIVATE_KEY" \
        --query "$NETWORK_NODE_URL" \
        --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
        --network 2 \
    "$TO_ADDRESS" "$AMT")
    local transfer_public_status=$?

    if [ $transfer_public_status -eq 0 ]; then
        log "Executed transfer_public $AMT to $TO_ADDRESS" $transfer_log
        local transaction=$(echo "$output" | tail -n 1)
        eval "$TX_ID='$transaction'"
        log "  ${NAME} Transaction:  $transaction " $transfer_log
    else
        log "FAILED:  transfer_public of $AMT to address $TO_ADDRESS" $transfer_log
        exit 1
    fi 

    # Wait for the transfer to complete by checking the balance of the DELEGATOR_ADDRESS
    log "Waiting for the transfer to complete..." $transfer_log
    while true; do
        local balance_response=$(curl -s ${NETWORK_NODE_URL}/canary/program/credits.aleo/mapping/account/${TO_ADDRESS})
        local balance=$(echo $balance_response | sed 's/"//g' | sed 's/u64//')
        if [ -n "$balance" ] && [ "$(echo "$balance >= $pre_balance + $clean_amount" | bc)" -eq 1 ]; then
            log "Confirmed balance of $balance in address $TO_ADDRESS" $transfer_log
            break
        fi
        sleep 1
    done
    log "Transfer confirmed on-chain." $transfer_log
    log "END Transfer to $NAME " $transfer_log
}