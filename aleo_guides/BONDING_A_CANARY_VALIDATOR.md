# Bonding and Running a Validator on Aleo's CanaryNet

*NOTE:  This document is not specific to `snarkops`.  It is intended for the Aleo CanaryNet community members who are running generic `snarkOS` validator and nodes unmanaged by `snarkops`.*

To fund, delegate, and bond validators, use this checklist of checklists and their specific scripts:

- [ ] Aleo Foundation Checklist 1:  [Delegate from the Aleo credits from the Foundation to a Validator's bonding address](#bonding-process-and-checklist-for-the-foundation)
- [ ] Validator Entity Checklist 1:  [Bond a validator using it's bonding address and withdrawal address](#bonding-process-for-the-validator-entity)
- [ ] Validator Entity Checklist 2: [Start and run a bonded validator `snarkOS` node](#starting-the-bonded-validator-node)
- [ ] Aleo Foundation Checklist 2: Verify validator committe members' nodes live on CanaryNet
- [ ] Validator Entity Checklist 3:  Monitor validator sync and block production and client sync live on CanaryNet

Use the above checklists as the process for funding and bonding validators.  The Foundation Checklist needs to happen first, followed by the others.

## Aleo CanaryNet Validators

Each Aleo CanaryNet Validator community entity (i.e., a person or team who wishes to run a validator that participates in the network committee) must configure and run one or more `snarkOS` validator nodes.  Additionally, it is recommended that Validator entities run one or more clients to shield validator nodes from public interference. 

### Addresses and Private Keys

Each Validator node is associated with an Aleo Network address for a specific private key.  The generation of addresses and private keys is beyond the scope of this document, but instructions can be found [here](https://blahblah.net).  Since CanaryNet is not used for production, the protection of private keys is not as critical; however, praticing running a secure environment is encouraged on CanaryNet.  The details of securing private keys on production servers are complicated and tricky.  This guide includes a few recommendations; however, this document should not be used as explicit instructions for securing private keys in production environments.  

### Recommended Validator and Client Topology

Each CanaryNet participant is encouraged to run one or more the following validator clusters:

- A `snarkOS` node configured to run with the `--validator` option which uses two private keys and their associated addresses:
    1.  A private key/address pair to for the validator bonding address.
    2.  A private key/address pair for the withdrawal address.
- One to three `snarkOS` nodes configured to run with the `--client` option.  Private keys and addresses are not tracked for CanaryNet clients, and their security is not critical.

### Validator Bonding and Withdrawal Addresses

For each validator in a given network, there are two associated addresses:  (1) The bonding address, and (2) the withdrawal address.  Each validator node must have a unique bonding address.  Withdrawal addresses can be re-used even if one is running multiple validators.  One must create these addresses and communicate the bonding address to the CanaryNet Validator committee so they can be funded.  The Aleo Foundation delegate 10,001,000 aleo credits required for a validator to participate in the validator committee.  Additionally, each validator bonding address must maintain at least 100 credits at all times.  To help facilitate this, the Aleo Foundation will include an additional amount of credits.

#### For the Foundation:

A single Aleo address can only delegate to *one* validator bonding address.  For every validator address delegated to, the Foundation must use a unique funding address.

#### For the Validator Entity:

After the Foundation has delegated the required funds to your validator bonding address, you may begin the process of bonding and starting your validator.

## Bonding Process and Checklist for the Foundation

Here is the checklist for the Foundation to bond in a set of validators and boostrap CanaryNet with the required members.

- [ ] Gather the list of validator teams who are to participate in CanaryNet
- [ ] Determine the number of validators each team will run.
- [ ] For each validator a team will run, record their bonding address to which Foundation will delegate required credits.
- [ ] Generate a unique funding address for each validator bonding address
- [ ] Fund the validator address using the [`fund_validator.sh`](#the-fund_validatorsh-script) script
- [ ] Fund each unique Foundation funding address with `10_001_000_000_000`` microcredits using the [`fund_delegator.sh`](#the-fund_delegatorsh-script) script.
- [ ] Verify the funding address re3ceived the credits on-chain using the [`verify_balance.sh`](#the-verify_balancesh-script) script
- [ ] After all balances have been verified, delegate from each unique funding address `10_001_000_000_000` credits to each validator bonding address using [`delegate_to_validator.sh`](#the-delegate_to_validatorsh-script)
- [ ] Verify each validator bonding address received the delegated credits on-chain using [`verify_delegation.sh`](#the-verify_delegationsh-script) 
- [ ] Notify each validator their bonding addresses have received the delegated credits

### Gathering Validator Entities

Create a list of all the teams who wish to participate in CanaryNet.  This would likely be a Google Sheet with a row for each entity's validator and client nodes.  You will need to fund and delegate to these entities using the addresses they provide to you.

Gather the IP addresses and the machine specs for each of the validator entity's nodes.  You will need to identify which nodes are a validator and which ones are clients.  Each validator should have a public address.  You will use these public validator addresses when funding and delegating to the validator so their nodes can participate in the CanaryNet committee.

### Gather Bonding Addresses

### Generate Delegator Addresses

### Fund Each Delegator Address 

### Verify Delegator Balances

### Delegate to Validators

### Verify Delegations

### Notify Validators of Delegations

## Bonding Process for the Validator Entity 

Here is the checklist for the validator entity who wants to participate in the CanaryNet committee using a validator node.

- [ ] Contact Aleo Foundation and indicate you wish to run a Validator on CanaryNet
- [ ] Allocate compute resources for the nodes you wish to run on CanaryNet
- [ ] Clone and build `snarkOS` from the `AleoNet` repository with the release tag specified by the Aleo Foundation 
- [ ] Generate validator and withdrawal keys and provide them to the Aleo Foundation
- [ ] Deploy and configure the `snarkOS` binary on your nodes' compute resources
- [ ] Notify Aleo Foundation that your nodes are ready
- [ ] Using the [`verify_funds.sh`](#the-verify_fundssh-script) script, Verify your validator addresses have been funded (delegated to) by the Aleo Foundation
- [ ] Using the [`bond_validator.sh`](#the-bond_validatorsh-script) script, bond your validators using your validator addresses and withdrawal address
- [ ] Using the [`verify_validator_bonding.sh`](#the-verify_validator_bondingsh-script) script, verify your validator addresses have the minimum balance bonded
- [ ] Start your validator nodes

## Starting the Bonded Validator Node

# `snup`'s Scripts to Facilitate Funding, Bonding, and Delegation

Below is a collection of `bash` scripts to accomplish all we're trying to do here.  First let's start with the script that all of the scripts include and source to set up and verify the enviroment for CanaryNet transactions, the `environmnet.sh` script.

## The [`environment.sh`](../scripts/environment.sh) Script

See:  [`environment.sh`](../scripts/environment.sh)

For all of this to work, we need to first clone and build snarkOS from the [AleoNet github project](https://github.com/AleoNet/snarkOS).  Aleo Foundation will likely provide a specific release tag to use for the specific version of snarkOS that is running CanaryNet.  Make sure you use the release tag or specific revision they specify.

This script assumes that you've check out and built snarkOS in a directory parallel to the `snups` directory.

This script sets SNARKOS_BIN and NETWORK_NODE_URL environment variables.  It then checks if NETWORK_NODE_URL is set. If not, it prints an error message and exits with status 1.  It also makes sure the snarkOS binary exists and is executable.  

If the NETWORK_NODE_URL is valid, it will report that it successfully connected and retrieved the genesis block.  This means you good to go.


## Foundation Funding and Delegation Scripts

### The `fund_validator.sh` Script

See:  [`fund_validator.sh`](../scripts/fund_validator.sh)

### The `fund_delegator.sh` Script

See:  [`fund_delegator.sh`](../scripts/fund_delegator.sh)

### The `verify_balance.sh` Script

See:  [`verify_balance.sh`](../scripts/verify_balance.sh)

### The `verify_balance.sh` Script

See:  [`verify_balance.sh`](../scripts/verify_balance.sh)

### The `verify_delegation.sh` Script

See:  [`verify_delegation.sh`](../scripts/verify_delegation.sh)

## Validator Entity Bonding Scripts

### The `verify_funds.sh` Script

See:  [`verify_funds.sh`](../scripts/verify_funds.sh)

### The `bond_validator.sh` Script

See:  [`bond_validator.sh`](../scripts/bond_validator.sh)

### The `verify_validator_bonding.sh` Script

See:  [`verify_validator_bonding.sh`](../scripts/verify_validator_bonding.sh)

## Suggested Validator `snarkOS` Management Scripts


<!--
# ---
# bond test
# ---
# --- transfer 200 credits to validator 0
# scli env action execute transfer_public --private-key committee.0 validators.0 200_000_000u64
#
# --- transfer 10,000,100 credits to delegator 0
# scli env action execute transfer_public --private-key committee.0 delegator.0 10_000_100_000_000u64
#
# --- delegate 10,000,000 credits to validator 0
# scli env action execute bond_public --private-key delegator.0 validators.0 del_withdraw.0 10_000_000_000_000u64
#
# --- bond 100 credits to validator 0
# scli env action execute bond_validator --private-key validators.0 val_withdraw.0 100_000_000u64 100u8
#
# --- set validator 0 to be online
# scli env action online validator/bonded-0
-->






