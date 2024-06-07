# Bonding and Running a Validator on Aleo's CanaryNet

*WARNING:  This document is not specific to `snarkops`.  It is intended for the Aleo CanaryNet community members who are running generic `snarkOS` validator and nodes unmanaged by `snarkops`.  This process  is inherently insecure as it involves using private keys on machines connected to the internet.  Do NOT use this process to deploy validators or networks in production.*

# tl;dr

Note:  If you want all the hows and whys, go to the [Full Details](#full-details) section.  

## Overall Process for Both Foundation and Community Validators

To fund, delegate, and bond validators, use this checklist of checklists and their specific scripts:

- [ ] Aleo Foundation Checklist 1:  [Delegate Aleo credits from Foundation funding address to a Validator's bonding address](#bonding-process-and-checklist-for-the-foundation)
- [ ] Validator Checklist 1:  [Bond a validator using it's bonding address and withdrawal address](#bonding-process-for-the-validator-entity)
- [ ] Validator Checklist 2: [Start and run a bonded validator `snarkOS` node](#starting-the-bonded-validator-node)
- [ ] Aleo Foundation Checklist 2: Verify validator committee member's nodes live on CanaryNet
- [ ] Validator Checklist 3:  Monitor validator sync and block production and client sync live on CanaryNet

## Bonding Process and Checklist for the Foundation
Here is the checklist for the Foundation to bond in a set of validators and boostrap CanaryNet with the required members.
- [ ] [Gather the list of validator teams](#gathering-validator-entities) who are to participate in CanaryNet
- [ ] [Record the address](#gather-validator-addresses) of each validator
- [ ] [Fund and bond a delegator](#fund-and-bond-delegator) for each validator.
- [ ] [Archive addresses and transaction logs](#archiving-fundings).
- [ ] Notify each validator their bonding addresses have received the delegated credits and they can start their bonding process.

## Bonding Process for the Validator Entity 
Here is the checklist for the validator entity who wants to participate in the CanaryNet committee using a validator node.
- [ ] Generate your address and withdrawal keys and provide the public address to the Aleo Foundation.
- [ ] Deploy and configure the `snarkOS` binary on your nodes' compute resources with your private key.
- [ ] Notify Aleo Foundation that your nodes are ready
- [ ] [Bond your validator](#the-bond_validatorsh-script) using your validator private key, address, and withdrawal address
- [ ] Start your validator nodes


# Full Details

Use the above checklists as the process for funding and bonding validators.  The Foundation Checklist needs to happen first, followed by the others.  When CanaryNet is started, this process is coordinated by the Aleo Foundation.  This process can also be followed anytime a new validator is added to the network.

## Aleo CanaryNet Validators

Each Aleo CanaryNet Validator community entity (i.e., a person or team who wishes to run a validator that participates in the network committee) must configure and run one or more `snarkOS` validator nodes.  Additionally, it is recommended that Validator entities run one or more clients to shield validator nodes from public interference. 

### Addresses and Private Keys

Each Validator node is associated with an Aleo Network address for a specific private key.  The secure management of addresses and private keys is beyond the scope of this document; however, this project provides several convenience scripts to generate keys and verify bondings, delegations, and balances. Since CanaryNet is not used for production, the protection of private keys is not as critical; however, practicing running a secure environment is encouraged on CanaryNet.  The details of securing private keys on production servers are complicated and tricky.  This guide includes a few recommendations; however, this document should not be used as explicit instructions for securing private keys in production environments.  

*WARNING: Production private keys should never be stored on any computer connected to a network.*

### Recommended Validator and Client Topology

Each CanaryNet participant is encouraged to run one or more the following validator clusters:

- A `snarkOS` node configured to run with the `--validator` option which uses two private keys and their associated addresses:
    1.  A private key/address pair for the validator node address.
    2.  A private key/address pair for the withdrawal address.
- One to three `snarkOS` nodes configured to run with the `--client` option.  Private keys and addresses are not tracked for CanaryNet clients, and their security is not critical.

### Validator Bonding and Withdrawal Addresses

For each validator in a given network, there are two associated addresses:  (1) The bonding address, and (2) the withdrawal address.  Each validator node must have a unique bonding address.  Withdrawal addresses can be re-used even if one is running multiple validators.  One must create these addresses and communicate the validator address to the CanaryNet Validator committee so it can be funded and delegated to.  The Aleo Foundation will 10,000,200 aleo credits required for a validator to participate in the validator committee.  Additionally, each validator address must maintain at least 100 credits at all times.  To help facilitate this, the Aleo Foundation will include an additional amount of credits.  

Once the Foundation has funded a validator address, the validator bonding script provided here will transfer 100 credits from the validator address to its withdrawal address as a convenience for those running the validator.

#### For the Foundation:

A single Aleo address can only delegate to *one* validator bonding address.  For every validator address delegated to, the Foundation must use a unique funding address.  Details are contained in the [Fund and Bond Delegators](#fund-and-bond-delegator) section.  A single script is provided to generate delegator accounts, an associated withdrawal account, and all transfers and bonding is done in one command.  It is important that the Foundation archive the results of the fundings as all keys and transactions are logged.  The results of the fundings will be used to monitor progress and status of all validators in the network.  Also, without the keys generated by the script, Foundation will not be able to recover the credits delegated to validators.  While CanaryNet is only a temporary network and will likely be reset, it will eventually stabilize and those keys will be needed long-term (potentially years).

#### For the Validator Entity:

After the Foundation has delegated the required funds to your validator bonding address, you may begin the process of bonding and starting your validator.  This project provides a script to bond your validator using your key, address, and withdrawal address.  It is important to keep track of these keys (bonding and withdrawal) as you will use them to harvest commissions for running your validator as well as accept delegations from others.

### Gathering Validator Entities

Foundation must create a list of all the teams who wish to participate in CanaryNet.  This would likely be a Google Sheet with a row for each entity's validator and client nodes.  You will need to fund and delegate to these entities using the addresses they provide to you.  *Record a one-word unique name for each validator.* . You will use this name while funding and delegating to the validator.  It will be used to log and archive keys and transactions for later use.

Gather the IP addresses and the machine specs for each of the validator entity's nodes.  You will need to identify which nodes are a validator and which ones are clients.  Each validator should have a public address and a withdrawal address.  You will use these public validator addresses when funding and delegating to the validator so their nodes can participate in the CanaryNet committee.

### Gather Validator Addresses

Each validator on CanaryNet must have a valid Aleo address.  Record this address for each validator name.  Each validator must also provide their withdrawal address. You will use these address to fund with 200 credits each for operation and you will delegate 10_000_000 credits to the validator address.  All of this is automated in the `fund_and_bond_delegator.sh` script.  

### Fund and Bond Delegator

Once you have gathered the validator names and addresses, you will need to fund and bond a delegators and it's withdrawal address to each validator address.  The minimum amount for a validator to operate is 10_000_000 credits (i.e., 10_000_000_000_000 microcredits). The [`fund_and_bond_delegator.sh`](../scripts/fund_and_bond_delegator.sh) script below automatically creates all delegator and the associated withdrawl accounts.  You do not need to create these in advance.

The script also requires a Fee specified.  This is the additional convenience amount the Foundation gives to the validator address and it's associated withdrawal address to ease operation.  It is recommended the amount be `200000000u64` which is 200 Aleo Credits.

Use the [`fund_and_bond_delegator.sh`](../scripts/fund_and_bond_delegator.sh) script.  

Example:

``` 
$ ./fund_and_bond_delegator.sh \
    APrivateKey1zkpHawWywic4aEHCN9cexUA1trb7voc23fXe2vH8DrfonES \      # The Foundation funding private key
    aleo1rzq3lwwd4ycdqm3y5h9pet2n0rn4wmuagmgsmfhp48nrcl0mx5gq6g480s \  # The Foundation address (used for balance verification)
    aleo1cvln9yys2hwlptq3sjc5kv5ugvcjxsq5nap6gq4r77ev8wv6859qh839ml \  # The Validator address
    monadicus \ .                                                      # The one-word unique name for the validator
    10000000000000u64  \                                               # 10_000_000 Aleo Credits in microcredits 
    200000000u64                                                       # The recommended convenience fee.
```

The first argument is the Foundation's private key containing the source funds for all delegators.

The second argument is the public address of the Foundation's funding account which is used to verify the required balance before any transfer happens.

Third argument is the validator account to which we will bond a new delegator account (automatically generated and logged).

The fourth argument is 10 million credits in the form of microcredits.

The last argument is 200 credits in the form of microcredits, the convenience fees to be transferred into all the generated accounts along with the validator's withdrawal account and node address.

These keys and accounts are just examples and not real accounts.  They are valid but unused.  You will need to provide your own accounts for this.  The funding addresses are unique every time we create a new network.

<!-- >
### Verify Delegator Balances

### Delegate to Validators

### Verify Delegations

### Notify Validators of Delegations

## Starting the Bonded Validator Node
<! -->

# `snup`'s Scripts to Facilitate Funding, Bonding, and Delegation

Below is a collection of `bash` scripts to accomplish all we're trying to do here.  First let's start with the script that all of the scripts include and source to set up and verify the enviroment for CanaryNet transactions, the `environmnet.sh` script.

## The [`environment.sh`](../scripts/environment.sh) Script

See:  [`environment.sh`](../scripts/environment.sh)

For all of this to work, we need to first clone and build snarkOS from the [AleoNet github project](https://github.com/AleoNet/snarkOS).  Aleo Foundation will likely provide a specific release tag to use for the specific version of snarkOS that is running CanaryNet.  Make sure you use the release tag or specific revision they specify.

This script assumes that you've check out and built snarkOS in a directory parallel to the `snups` directory.

This script sets SNARKOS_BIN and NETWORK_NODE_URL environment variables.  

SNARKOS_BIN is the path to the `snarkOS` binary, including the name of the binary itself.  

NETWORK_NODE_URL is a URL of a valid running CanaryNet client or validator node.  This node will be used to execute all transactions initiated by these scripts.  

It then checks if NETWORK_NODE_URL is set. If not, it prints an error message and exits with status 1.  It also makes sure the snarkOS binary exists and is executable.  

If the NETWORK_NODE_URL is valid, it will report that it successfully connected and retrieved the genesis block.  This means you are good to go.


## Foundation Funding and Delegation Scripts

See:  [`fund_and_bond_delegator.sh`](../scripts/fund_and_bond_delegator.sh)

## Validator Entity Bonding Scripts

### The `bond_validator.sh` Script

See:  [`bond_validator.sh`](../scripts/bond_validator.sh)

## Convenience Scripts

### The `get_balance.sh` Script

See:  [`get_balance.sh`](../scripts/get_balance.sh)

### The `get_delegated.sh` Script

See:  [`get_delegated.sh`](../scripts/get_delegated.sh)

### The `get_mapping.sh` Script

See:  [`get_mapping.sh`](../scripts/get_mapping.sh)

### The `get_bonded_amount.sh` Script

See:  [`get_bonded_amount.sh`](../scripts/get_bonded_amount.sh)

### The `new_account.sh` Script

See:  [`new_account.sh`](../scripts/new_account.sh)

### The `transfer_public.sh` Script

See:  [`transfer_public.sh`](../scripts/transfer_public.sh)

## Validator Entity Bonding Scripts

### The `bond_validator.sh` Script

See:  [`bond_validator.sh`](../scripts/bond_validator.sh)


## Suggested Validator `snarkOS` Management Scripts






