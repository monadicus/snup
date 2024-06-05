#!/bin/bash

# Source the environment variables
echo "Sourcing environment variables from environment.sh..."
source ./environment.sh
echo "Environment variables sourced."

# Make a director to hold funding log files.
mkdir -p ./fundings

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

# Generate a new address using the snarkOS binary
echo "Generating a new address using the snarkOS binary..."
new_account_output=$($SNARKOS_BIN account new)
echo "New address generated."

# Extract the new private key, view key, and address from the output
echo "Extracting the new private key, view key, and address from the output..."
NEW_PRIVATE_KEY=$(echo "$new_account_output" | grep 'Private Key' | awk '{print $3}')
NEW_VIEW_KEY=$(echo "$new_account_output" | grep 'View Key' | awk '{print $3}')
DELEGATOR_ADDRESS=$(echo "$new_account_output" | grep 'Address' | awk '{print $2}')
echo "New private key, view key, and address extracted."

# Print the new account details
echo "Generated new account:"
echo "  New Delegator Private Key: $NEW_PRIVATE_KEY"
echo "  New Delegator View Key: $NEW_VIEW_KEY"
echo "  New Delegator Address: $DELEGATOR_ADDRESS"

# Check the balance of the Foundation's account
echo "Checking the balance of the Foundation's account..."
foundation_balance_response=$(curl -s ${NETWORK_NODE_URL}/canary/program/credits.aleo/mapping/account/${FOUNDATION_ADDRESS})
foundation_balance=$(echo $foundation_balance_response | sed 's/"//g' | sed 's/u64//')

echo "Foundation's account balance: ${foundation_balance:-0}"
echo "Foundation's account balance checked."

# If the balance is null or less than the amount to fund, exit with an error
echo "Verifying if the Foundation's account has sufficient funds..."
if [ -z "$foundation_balance" ] || [ "$(echo "$foundation_balance < $CLEAN_AMOUNT" | bc)" -eq 1 ]; then
    echo "Error: Insufficient funds in the Foundation's account."
    exit 1
fi
echo "Sufficient funds available in the Foundation's account."

# Generate a second set of private key, view key, and address
echo "Generating a second set of private key, view key, and address using the snarkOS binary..."
new_withdraw_account_output=$($SNARKOS_BIN account new)
echo "Second set of private key, view key, and address generated."

# Extract the new private key, view key, and address from the output
echo "Extracting the new private key, view key, and address from the output..."
DELEGATOR_WITHDRAW_PRIVATE_KEY=$(echo "$new_withdraw_account_output" | grep 'Private Key' | awk '{print $3}')
DELEGATOR_WITHDRAW_VIEW_KEY=$(echo "$new_withdraw_account_output" | grep 'View Key' | awk '{print $3}')
DELEGATOR_WITHDRAW_ADDRESS=$(echo "$new_withdraw_account_output" | grep 'Address' | awk '{print $2}')
echo "Second set of private key, view key, and address extracted."

# Print the second set of account details
echo "Generated second account:"
echo "  Delegator Withdraw Private Key: $DELEGATOR_WITHDRAW_PRIVATE_KEY"
echo "  Delegator Withdraw View Key: $DELEGATOR_WITHDRAW_VIEW_KEY"
echo "  Delegator Withdraw Address: $DELEGATOR_WITHDRAW_ADDRESS"

# Save the generated accounts and funded amount to a file
output_file="./fundings/${VALIDATOR_NAME}_funding.txt"

echo "Saving generated accounts and funded amount to $output_file..."
{
    echo "Generated new account:"
    echo "  New Delegator Private Key: $NEW_PRIVATE_KEY"
    echo "  New Delegator View Key: $NEW_VIEW_KEY"
    echo "  New Delegator Address: $DELEGATOR_ADDRESS"
    echo "Generated second account:"
    echo "  Delegator Withdraw Private Key: $DELEGATOR_WITHDRAW_PRIVATE_KEY"
    echo "  Delegator Withdraw View Key: $DELEGATOR_WITHDRAW_VIEW_KEY"
    echo "  Delegator Withdraw Address: $DELEGATOR_WITHDRAW_ADDRESS"
    echo "Funding amount: $AMOUNT ..."
} >> "$output_file"
echo "Details saved to $output_file."

echo >> "$output_file"

# Transfer the amount to the new DELEGATOR_ADDRESS
echo "Transferring $AMOUNT to the new delegator address..."
$SNARKOS_BIN developer execute credits.aleo transfer_public \
 --private-key "$FOUNDATION_PRIVATE_KEY" \
 --query "$NETWORK_NODE_URL" \
 --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
 --network 2 \
 "$DELEGATOR_ADDRESS" "$AMOUNT"
echo "Transfer initiated."


# Wait for the transfer to complete by checking the balance of the DELEGATOR_ADDRESS
echo "Waiting for the transfer to complete..."
sleep 8
while true; do
    delegator_balance_response=$(curl -s ${NETWORK_NODE_URL}/canary/program/credits.aleo/mapping/account/${DELEGATOR_ADDRESS})
    delegator_balance=$(echo $delegator_balance_response | sed 's/"//g' | sed 's/u64//')
    echo "Delegator's account balance: ${delegator_balance:-0}"
    
    if [ -n "$delegator_balance" ] && [ "$(echo "$delegator_balance >= $CLEAN_AMOUNT" | bc)" -eq 1 ]; then
        echo "Transfer completed. Delegator balance: $delegator_balance"
        break
    fi
    
    echo "Transfer not completed yet. Current balance: ${delegator_balance:-0}. Checking again in 5 seconds..."
    sleep 5
done

# Execute the fund delegator command
echo "Executing the fund delegator command..."
$SNARKOS_BIN developer execute credits.aleo bond_public \
 --private-key "$FOUNDATION_PRIVATE_KEY" \
 --query "$NETWORK_NODE_URL" \
 --broadcast "$NETWORK_NODE_URL/canary/transaction/broadcast" \
 --network 2 \
 "$DELEGATOR_ADDRESS" "$DELEGATOR_WITHDRAW_ADDRESS" "$AMOUNT"
echo "Fund delegator command executed."