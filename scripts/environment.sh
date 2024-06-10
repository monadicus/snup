#!/bin/bash

# Set environment variables
# This is the path to the snarkOS binary.
# Assumes you've checked out the snarkOS repo and built the binary
# in a directory called `snarkOS` in a directory parallel to this repository.
export SNARKOS_BIN="../../snarkOS/target/release/snarkos"

# You can replace this with your own network node URL or use it if you like.
#   This uses MONADIC.US's public $NETWORK_NAME network node.
#export NETWORK_NODE_URL="http://99.48.167.129:3030"
export NETWORK_NODE_URL="http://localhost:3030"

export NETWORK_NAME="canary"
export NETWORK_ID="2"

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
response=$(curl -s ${NETWORK_NODE_URL}/$NETWORK_NAME/block/0)

# Check if the response contains a block_hash
if echo "$response" | grep -q '"block_hash"'; then
    #echo "NETWORK_NODE_URL: ${NETWORK_NODE_URL} is valid and responded with a block_hash."
    :
else
    echo "Error: NETWORK_NODE_URL is not valid or did not respond correctly."
    exit 1
fi

# Function to clean the 'u64' and quotes off of an amount
#  so it can be used in calculations.
clean() {
    echo $(echo $1 | sed 's/"//g' | sed 's/u64//')
}

# A function to convert "131234413242432u64" to 12,123,223.123456Å
to_credits() {
    # Check the number of arguments
    if [ $# -ne 1 ]; then
        echo "Error: Incorrect number of arguments."
        echo "Usage: to_credits <123456789u64>"
        return 1
    fi
    # Input number in microcredits
    microcredits="$1"

    # Remove any surrounding quotes and the 'u64' suffix
    number=$(echo "$microcredits" | tr -d '"' | sed 's/u64//')

    # Ensure the number is valid
    if ! [[ "$number" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid number format."
      return 1
    fi

    # Convert microcredits to credits
    credits=$(echo "scale=6; $number / 1000000" | bc)

    # Format the result with commas
    formatted_credits=$(printf "%'.6f" $credits)

    # Trim all trailing zeros
    trimmed_credits=$(echo "$formatted_credits" | awk '{ sub(/\.?0+$/, ""); sub(/(\.[0-9]*[1-9])0+$/, "\\1"); print }')

    # Append the Å symbol
    formatted_credits_with_symbol="${trimmed_credits}Å"

    echo $formatted_credits_with_symbol
}
new_account() {
    # Check the number of arguments
    if [ $# -ne 1 ]; then
        echo "Error: Incorrect number of arguments."
        echo "Usage: new_account <NAME>"
        echo "   Note: "
        echo "        <NAME> is a one-word human-readable name for the new account."
        echo "               A new file will be created as ./accounts/<NAME>_account.txt"
        return 1
    fi
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
    # Check the number of arguments
    if [ $# -ne 4 ]; then
        echo "Error: Incorrect number of arguments."
        echo "Usage: save_account <NAME> <PRIVATE_KEY> <VIEW_KEY> <ADDRESS>"
        echo "   Note: "
        echo "        <NAME> is a one-word human-readable name for the new account."
        echo "               A new file will be created as ./accounts/<NAME>_account.txt"
        return 1
    fi
    local NAME=$1
    local NEW_PRIVATE_KEY=$2
    local NEW_VIEW_KEY=$3
    local NEW_ADDRESS=$4
    local account_file="./accounts/${NAME}.key"
    # Print the new account details
    log "  " $account_file
    log "        TYPE | VALUE:" $account_file
    log "------------------------------------------------------------------------" $account_file
    log " Private Key | $NEW_PRIVATE_KEY" $account_file
    log "    View Key | $NEW_VIEW_KEY" $account_file
    log "     Address | $NEW_ADDRESS" $account_file
}

get_balance() {
    # Check the number of arguments
    if [ $# -ne 1 ]; then
        echo "Error: Incorrect number of arguments."
        echo "Usage: get_balance <ADDRESS>"
        echo "  Fetches the balance for the address."
        return 1
    fi
    local ADDRESS=$1
    local balance_response=$(curl -s ${NETWORK_NODE_URL}/$NETWORK_NAME/program/credits.aleo/mapping/account/${ADDRESS})
    local balance=$(echo ${balance_response} | sed 's/"//g' | sed 's/u64//')
    if [ $balance = "null" ] ; then
        echo "0"
    else 
        echo $balance
    fi
}

transfer_public () {
    # Check the number of arguments
    if [ $# -ne 5 ]; then
        echo "Error: Incorrect number of arguments."
        echo "Usage: transfer_public <PRIVATE_KEY> <TO_ADDRESS> <AMOUNT> <NAME> <TX_ID>"
        echo "   Note: "
        echo "        <NAME> is a one-word human-readable name for the target address."
        echo "               It will be used to name a log file for all transfers"
        echo "               for this name in the ./transfers directory."
        echo "        <TX_ID> is the name of the environment variable into which"
        echo "               the on-chain transaction ID will be stored. Use this"
        echo "               ID to log that the transaction occured."
        return 1
    fi
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
    local pre_balance=$(get_balance $TO_ADDRESS)
    local clean_amount=$(clean $AMT)
    log "Balance before transfer: $(to_credits $pre_balance) ($pre_balance)" $transfer_log
    # Transfer additional credits to DELEGATOR_WITHDRAWAL_ADDRESS
    log "Transferring $(to_credits $AMT) ($AMT)  " $transfer_log
    log "  From Private Key:  $PRIVATE_KEY" $transfer_log
    log "        To Address:  $TO_ADDRESS ..." $transfer_log
    log "   " $transfer_log

    local output=$($SNARKOS_BIN developer execute credits.aleo transfer_public \
        --private-key "$PRIVATE_KEY" \
        --query "$NETWORK_NODE_URL" \
        --broadcast "$NETWORK_NODE_URL/$NETWORK_NAME/transaction/broadcast" \
        --network $NETWORK_ID \
        "$TO_ADDRESS" "$AMT")
    local transfer_public_status=$?

    if [ $transfer_public_status -eq 0 ]; then
        log "Executed transfer_public $(to_credits $AMT) ($AMT) to $TO_ADDRESS" $transfer_log
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
        local balance=$(get_balance $TO_ADDRESS)
        if [ -n "$balance" ] && [ "$(echo "$balance >= $pre_balance + $clean_amount" | bc)" -eq 1 ]; then
            log "Confirmed balance of $(to_credits $balance) in address $TO_ADDRESS" $transfer_log
            break
        fi
        sleep 1
    done
    log "Transfer confirmed on-chain." $transfer_log
    log "END Transfer to $NAME " $transfer_log
}

get_mapping() {
    # Check the number of arguments
    if [ $# -ne 2 ]; then
        echo "Error: Incorrect number of arguments."
        echo "Usage: get_mapping <MAPPING> <ADDRESS>"
        return 1
    fi
    local URL="${NETWORK_NODE_URL}/$NETWORK_NAME/program/credits.aleo/mapping/$1/$2"
    echo $(curl -s $URL)
}
get_delegated() {
    # Check the number of arguments
    if [ $# -ne 1 ]; then
        echo "Error: Incorrect number of arguments."
        echo "Usage: get_delegated <ADDRESS>"
        return 1
    fi
    get_mapping "delegated" $1
}


get_bonded_balance() {
    # Check the number of arguments
    if [ $# -ne 1 ]; then
        echo "Error: Incorrect number of arguments."
        echo "Usage: get_bonded_balance <DELEGATOR_ADDRESS>"
        return 1
    fi
    local DELEGATOR_ADDRESS=$1
    local mapping=$(get_mapping "bonded" $DELEGATOR_ADDRESS)
    # Extract the microcredits value using grep and sed

    local balance=$(echo $mapping | grep -oP '(?<=microcredits: )\d+u64' | sed 's/u64//')
    echo ${balance:-0}
}

bond_public() {
    # Check the number of arguments
    if [ $# -ne 7 ]; then
        echo "Error: Incorrect number of arguments."
        echo "Usage: bond_public <PRIVATE_KEY> <DELEGATOR_ADDRESS> <VALIDATOR_ADDRESS> <WITHDRAWAL_ADDRESS> <AMOUNT> <NAME> <TX_ID>"
        echo "   Note: "
        echo "        <NAME> is a one-word human-readable name for the validator."
        echo "               It will be used to name a log file for this bonding"
        echo "               in the ./bondings directory."
        echo "        <TX_ID> is the name of the environment variable into which"
        echo "               the on-chain transaction ID will be stored. Use this"
        echo "               ID to log that the transaction occured."
        return 1
    fi
    # Assign input arguments to variables
    local PRIVATE_KEY=$1
    local DELEGATOR_ADDRESS=$2
    local VALIDATOR_ADDRESS=$3
    local WITHDRAW_ADDRESS=$4
    local AMOUNT=$5
    local NAME=$6
    local TX_ID=$7

    local bonding_log="./bondings/${NAME}_bond_public.log"

    log "   " $bonding_log
    log "   " $bonding_log
    log "BEGIN bond_public to $NAME " $bonding_log
    log "   " $bonding_log
    # Fetch the data using curl
    local pre_balance=$(get_bonded_balance $DELEGATOR_ADDRESS)
    log "Delegators's bonded balance before transfer: $(to_credits $pre_balance) ($pre_balance)" $bonding_log
    log "  Delegating $(to_credits $AMOUNT) ($AMOUNT) to Validator $NAME " $bonding_log
    log "     From Private Key:  $PRIVATE_KEY" $bonding_log
    log "  .        To Address:  $VALIDATOR_ADDRESS" $bonding_log
    log "   " $bonding_log

    local output=$($SNARKOS_BIN developer execute credits.aleo bond_public \
        --private-key "$PRIVATE_KEY" \
        --query "$NETWORK_NODE_URL" \
        --broadcast "$NETWORK_NODE_URL/$NETWORK_NAME/transaction/broadcast" \
        --network $NETWORK_ID \
        "$VALIDATOR_ADDRESS" "$WITHDRAW_ADDRESS" "$AMOUNT")
    local bond_public_status=$?

    if [ $bond_public_status -eq 0 ]; then
        log "Executed bond_public $AMOUNT to $VALIDATOR_ADDRESS" $bonding_log
        local transaction=$(echo "$output" | tail -n 1)
        eval "$TX_ID='$transaction'"
        log "  ${NAME} Transaction:  $transaction " $bonding_log
    else
        log "FAILED:  bond_public of $AMOUNT to address $VALIDATOR_ADDRESS" $bonding_log
        exit 1
    fi 

    # Wait for the transfer to complete by checking the balance of the DELEGATOR_ADDRESS
    log "Waiting for the bonding to complete..." $bonding_log
    local clean_amount=$(clean $AMOUNT)
    while true; do
        local balance=$(get_bonded_balance $DELEGATOR_ADDRESS)
        if [ -n "$balance" ] && [ "$(echo "$balance >= $pre_balance + $clean_amount" | bc)" -eq 1 ]; then
            log "Confirmed balance of $balance in address $WITHDRAW_ADDRESS" $bonding_log
            break
        fi
        sleep 1
    done
    log "    Transaction confirmed on-chain." $bonding_log
    log "END bond_public to $NAME " $bonding_log

}

#
# Function to bond a validator.
bond_validator() {
    # Check the number of arguments
    if [ $# -ne 7 ]; then
        echo "Error: Incorrect number of arguments."
        echo "Usage: bond_validator <PRIVATE_KEY> <VALIDATOR_ADDRESS> <WITHDRAWAL_ADDRESS> <AMOUNT> <COMMISSION> <NAME> <TX_ID>"
        echo "   Note: "
        echo "        <NAME> is a one-word human-readable name for the validator."
        echo "               It will be used to name a log file for this bonding"
        echo "               in the ./bondings directory."
        echo "        <TX_ID> is the name of the environment variable into which"
        echo "               the on-chain transaction ID will be stored. Use this"
        echo "               ID to log that the transaction occured."
        return 1
    fi
    # Assign input arguments to variables
    local PRIVATE_KEY=$1
    local VALIDATOR_ADDRESS=$2
    local WITHDRAW_ADDRESS=$3
    local AMOUNT=$4
    local COMMISSION=$5
    local NAME=$6
    local TX_ID=$7

    local bonding_log="./bondings/${NAME}_bond_validator.log"

    log "   " $bonding_log
    log "   " $bonding_log
    log "BEGIN bond_validator to $NAME " $bonding_log
    log "   " $bonding_log
    # Fetch the data using curl
    local microcredits=$(get_bonded_balance $VALIDATOR_ADDRESS)
    log "Bonded Balance before transfer: $microcredits" $bonding_log
    # Transfer additional credits to DELEGATOR_WITHDRAWAL_ADDRESS
    log "  Bonding $AMOUNT for Validator $NAME " $bonding_log
    log "     From Private Key:  $PRIVATE_KEY" $bonding_log
    log "  .        To Address:  $VALIDATOR_ADDRESS" $bonding_log
    log "      Commission Rate:  $COMMISSION" $bonding_log
    log "   " $bonding_log

    local output=$($SNARKOS_BIN developer execute credits.aleo bond_validator \
        --private-key "$PRIVATE_KEY" \
        --query "$NETWORK_NODE_URL" \
        --broadcast "$NETWORK_NODE_URL/$NETWORK_NAME/transaction/broadcast" \
        --network $NETWORK_ID \
        "$VALIDATOR_ADDRESS" "$WITHDRAW_ADDRESS" "$AMOUNT" "$COMMISSION")
    local bond_validator_status=$?

    if [ $bond_validator_status -eq 0 ]; then
        log "Executed bond_validator $AMT to $VALIDATOR_ADDRESS" $bonding_log
        local transaction=$(echo "$output" | tail -n 1)
        eval "$TX_ID='$transaction'"
        log "  ${NAME} Transaction:  $transaction " $bonding_log
    else
        log "FAILED:  bond_validator of $AMT to address $VALIDATOR_ADDRESS" $bonding_log
        exit 1
    fi 

    # Wait for the transfer to complete by checking the balance of the DELEGATOR_ADDRESS
    log "Waiting for the transfer to complete..." $bonding_log
    local clean_amount=$(clean $AMOUNT)
    while true; do
        local balance=$(get_bonded_balance $VALIDATOR_ADDRESS)
        if [ -n "$balance" ] && [ "$(echo "$balance >= $pre_balance + $clean_amount" | bc)" -eq 1 ]; then
            log "Confirmed bonded amount of $balance for address $WITHDRAW_ADDRESS" $bonding_log
            break
        fi
        sleep 1
    done
    log "    Transaction confirmed on-chain." $bonding_log
    log "END bond_validator $NAME " $bonding_log

}