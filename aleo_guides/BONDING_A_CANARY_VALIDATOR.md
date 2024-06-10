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

A single Aleo address can only delegate to *one* validator bonding address.  For every validator address delegated to, the Foundation must use a unique delegator address.  Details are contained in the [Fund and Bond Delegators](#fund-and-bond-delegator) section.  A single script is provided to generate delegator accounts, an associated withdrawal account, and all transfers and bonding is done in one command.  It is important that the Foundation archive the results of the fundings as all keys and transactions are logged.  The results of the fundings will be used to monitor progress and status of all validators in the network.  Also, without the keys generated by the script, Foundation will not be able to recover the credits delegated to validators.  While CanaryNet is only a temporary network and will likely be reset, it will eventually stabilize and those keys will be needed long-term (potentially years).

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
    monadicus \                                                        # The one-word unique name for the validator
    10000000000000u64  \                                               # 10_000_000 Aleo Credits in microcredits 
    200000000u64                                                       # The recommended convenience fee.
```

The first argument is the Foundation's private key containing the source funds for all delegators.

The second argument is the public address of the Foundation's funding account which is used to verify the required balance before any transfer happens.

Third argument is the validator account to which we will bond a new delegator account (automatically generated and logged).

The argument argument is a one-word name (i.e., no spaces; hyphens or underscores OK) which is an alias for the validator team being bonded.  This name will be used as part of the log files and filenames for keys generated for future use.

The fifth argument is 10 million credits in the form of microcredits.

The last argument is 200 credits in the form of microcredits, specifying the convenience fees to be transferred into all the generated accounts along with the validator's withdrawal account and node address.

These keys and accounts are just examples and not real accounts.  They are valid but unused.  You will need to provide your own real funding accounts.  The funding addresses are unique every time we create a new network.

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

Before any scripts will work, we need to first clone and build snarkOS from the [AleoNet github project](https://github.com/AleoNet/snarkOS).  Aleo Foundation will likely provide a specific release tag to use for the specific version of snarkOS that is running CanaryNet.  Make sure you use the release tag or specific revision they specify.

This script assumes that you've check out and built snarkOS in a directory parallel to the `snups` directory.

This script sets SNARKOS_BIN, NETWORK_NODE_URL, NETWORK_NAME, and NETWORK_ID environment variables.  

SNARKOS_BIN is the path to the `snarkOS` binary, including the name of the binary itself.  

NETWORK_NODE_URL is a URL of a valid running CanaryNet client or validator node.  This node will be used to execute all transactions initiated by these scripts.  

It then checks if NETWORK_NODE_URL is set. If not, it prints an error message and exits with status 1.  It also makes sure the snarkOS binary exists and is executable.  

If the NETWORK_NODE_URL is valid, it will report that it successfully connected and retrieved the genesis block.  This means you are good to go.

The NETWORK_NAME is set to `canary` and the NETWORK_ID is `2`.  These settings are appropriate for CanaryNet.


## Foundation Funding and Delegation Scripts

See:  [`fund_and_bond_delegator.sh`](../scripts/fund_and_bond_delegator.sh)

This is the primary script used to create a delegator address, delegate from a funding address, and bond that delegator to a validator address.  It's usage is described above in the [Fund and Bond Delegator](#fund-and-bond-delegator) section.

Here we go into more detail on this script.  Below is another example of this script's execution.  This time we include the output of the script, which is logged and concatenated automatically to `./fundings/$NAME_funding.log` every time it is run.  This is why it is important to use the same meaningful one-word name for validator being funded each time the script is run.

Here's the second example which funds a validator for `monadicus`.  Explanations are given between each of the major steps this script executes.

Example:

```
% ./fund_and_bond_delegator.sh APrivateKey1zkp8ib2ZLsTSXxEPfwQ89ivgxNzLQ3yjjK2Hpdyc4JadHF9 aleo1r8a69q9z0v67t2w4ut4zamavyr09qr43vk7f584q6wpymg5qvg8scmerq8 aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w monadicus 10000000000000u64 150000000u64 
```
The above, using the funding key and address,APrivateKey1zkp8ib2ZLsTSXxEPfwQ89ivgxNzLQ3yjjK2Hpdyc4JadHF9 and 
aleo1r8a69q9z0v67t2w4ut4zamavyr09qr43vk7f584q6wpymg5qvg8scmerq8, creates a delegator account along with an associated withdrawal account, funds those accounts with 10,000,000Å plus 150Å for additional fees.  It then bonds (delegates) the 10,000,000Å to the specified validator address, 
aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w, using the name 'monadicus` for all of the audit logs (accounts, transfers, and funding).

Here is a breakdown of the log produced:

First it creates a new delegator account and saves the key to a file, `./accounts/monadicus_delegate.key`...

```
[2024-06-10 15:42:39]   
[2024-06-10 15:42:39]   
[2024-06-10 15:42:39]  BEGIN New Funding of Delegator for monadicus  
[2024-06-10 15:42:39]   
[2024-06-10 15:42:39] Generating a new delegate address...
[2024-06-10 15:42:39] New delegate address generated.
[2024-06-10 15:42:39]   
[2024-06-10 15:42:39] Extracting the new private key, view key, and address from the output...
[2024-06-10 15:42:39] New private key, view key, and address extracted.
[2024-06-10 15:42:39] Generated new account:
[2024-06-10 15:42:39]   New Delegator Private Key: APrivateKey1zkp9q8yK29Bvr18AvXzAzQaXqtUyQTFoCHyMvbhSVeREnoa
[2024-06-10 15:42:39]   New Delegator View Key: AViewKey1ku6GdVMaP9Kg4Dnd6AArikJrSGLx3WcfHYrfHQyCJJed
[2024-06-10 15:42:39]   New Delegator Address: aleo1jslffusy3mfz83smu04vpezs3uzaasrxy5tcupzg69h0cnryac9qe5f5j4
[2024-06-10 15:42:39] Saving the new delegate key to ./accounts/monadicus_delegate.key...
[2024-06-10 15:42:39]   
[2024-06-10 15:42:39]         TYPE | VALUE:
[2024-06-10 15:42:39] ------------------------------------------------------------------------
[2024-06-10 15:42:39]  Private Key | APrivateKey1zkp9q8yK29Bvr18AvXzAzQaXqtUyQTFoCHyMvbhSVeREnoa
[2024-06-10 15:42:39]     View Key | AViewKey1ku6GdVMaP9Kg4Dnd6AArikJrSGLx3WcfHYrfHQyCJJed
[2024-06-10 15:42:39]      Address | aleo1jslffusy3mfz83smu04vpezs3uzaasrxy5tcupzg69h0cnryac9qe5f5j4
```

Next, it checks the balance of the overall funding account for everything we are doing (assumed to be the Foundation's account used to fund all validators), and if there are sufficient funds, it generates the additional withdrawal address for the delegator.

```
[2024-06-10 15:42:39] Checking the balance of the funding's account...
[2024-06-10 15:42:39] funding's account balance: 999915839831762
[2024-06-10 15:42:39] Sufficient funds available in the funding's account.
[2024-06-10 15:42:39] Generating a second set of private key, view key, and address using the snarkOS binary...
[2024-06-10 15:42:39] Second set of private key, view key, and address generated.
[2024-06-10 15:42:39] Generated withdraw account:
[2024-06-10 15:42:39]   Delegator Withdraw Private Key: APrivateKey1zkp7xaeTFX4zcuhD5xs6UBfwdk9MVUXabZJkuN9EKU4Q7oW
[2024-06-10 15:42:39]   Delegator Withdraw View Key: AViewKey1jh9nVF58fTksKhQrEHogPq9Zm8veVJjppwKWVuVrgcic
[2024-06-10 15:42:39]   Delegator Withdraw Address: aleo13re02lya0suh3tlau3303xvjkjnscfqhwy7dzs8t7xnzlrkzkypsaf3fka
[2024-06-10 15:42:39] Saving the new delegate withdrawal key to ./accounts/monadicus_delegate_withdraw.key...
[2024-06-10 15:42:39]   
[2024-06-10 15:42:39]         TYPE | VALUE:
[2024-06-10 15:42:39] ------------------------------------------------------------------------
[2024-06-10 15:42:39]  Private Key | APrivateKey1zkp7xaeTFX4zcuhD5xs6UBfwdk9MVUXabZJkuN9EKU4Q7oW
[2024-06-10 15:42:39]     View Key | AViewKey1jh9nVF58fTksKhQrEHogPq9Zm8veVJjppwKWVuVrgcic
[2024-06-10 15:42:39]      Address | aleo13re02lya0suh3tlau3303xvjkjnscfqhwy7dzs8t7xnzlrkzkypsaf3fka
```

Now it funds the newly created delegator address with the 10mil Aleo credits.

```
[2024-06-10 15:42:39] Transferring 10,000,000Å (10000000000000u64) to the new delegator address...
[2024-06-10 15:42:39]    
[2024-06-10 15:42:39]    
[2024-06-10 15:42:39] BEGIN transfer_public to monadicus_delegator 
[2024-06-10 15:42:39]    
[2024-06-10 15:42:39] Balance before transfer: 0Å (0)
[2024-06-10 15:42:39] Transferring 10,000,000Å (10000000000000u64)  
[2024-06-10 15:42:39]   From Private Key:  APrivateKey1zkp8ib2ZLsTSXxEPfwQ89ivgxNzLQ3yjjK2Hpdyc4JadHF9
[2024-06-10 15:42:39]         To Address:  aleo1jslffusy3mfz83smu04vpezs3uzaasrxy5tcupzg69h0cnryac9qe5f5j4 ...
[2024-06-10 15:42:39]    
[2024-06-10 15:42:45] Executed transfer_public 10,000,000Å (10000000000000u64) to aleo1jslffusy3mfz83smu04vpezs3uzaasrxy5tcupzg69h0cnryac9qe5f5j4
[2024-06-10 15:42:45]   monadicus_delegator Transaction:  at1kzc4p8mpeuwlgnxvnr7wsdc83pmmz4hvdgr52n2r3r9nnmemrsfq8nmpcn 
[2024-06-10 15:42:45] Waiting for the transfer to complete...
[2024-06-10 15:42:51] Confirmed balance of 10,000,000Å in address aleo1jslffusy3mfz83smu04vpezs3uzaasrxy5tcupzg69h0cnryac9qe5f5j4
[2024-06-10 15:42:51] Transfer confirmed on-chain.
[2024-06-10 15:42:51] END Transfer to monadicus_delegator 
[2024-06-10 15:42:51] Transfered 10,000,000Å (10000000000000u64) to Delegator address aleo1jslffusy3mfz83smu04vpezs3uzaasrxy5tcupzg69h0cnryac9qe5f5j4.
```

Next it sends the additional convenience fees to the delegator's addresses (both the primary and withdraw address).  


```
[2024-06-10 15:42:51] Transferring 150Å (150000000u64) to the new delegator address...
[2024-06-10 15:42:51]    
[2024-06-10 15:42:51]    
[2024-06-10 15:42:51] BEGIN transfer_public to monadicus_delegator 
[2024-06-10 15:42:51]    
[2024-06-10 15:42:51] Balance before transfer: 10,000,000Å (10000000000000)
[2024-06-10 15:42:52] Transferring 150Å (150000000u64)  
[2024-06-10 15:42:52]   From Private Key:  APrivateKey1zkp8ib2ZLsTSXxEPfwQ89ivgxNzLQ3yjjK2Hpdyc4JadHF9
[2024-06-10 15:42:52]         To Address:  aleo1jslffusy3mfz83smu04vpezs3uzaasrxy5tcupzg69h0cnryac9qe5f5j4 ...
[2024-06-10 15:42:52]    
[2024-06-10 15:42:57] Executed transfer_public 150Å (150000000u64) to aleo1jslffusy3mfz83smu04vpezs3uzaasrxy5tcupzg69h0cnryac9qe5f5j4
[2024-06-10 15:42:57]   monadicus_delegator Transaction:  at1tqy9yyf6gutd6djmeyu2lwgpculput24lxzdwxq37ugphgqcnqgsf3rw2e 
[2024-06-10 15:42:57] Waiting for the transfer to complete...
[2024-06-10 15:43:05] Confirmed balance of 10,000,150Å in address aleo1jslffusy3mfz83smu04vpezs3uzaasrxy5tcupzg69h0cnryac9qe5f5j4
[2024-06-10 15:43:05] Transfer confirmed on-chain.
[2024-06-10 15:43:05] END Transfer to monadicus_delegator 
[2024-06-10 15:43:05] Transfered additional 150Å (150000000u64) to Delegator address aleo1jslffusy3mfz83smu04vpezs3uzaasrxy5tcupzg69h0cnryac9qe5f5j4.
[2024-06-10 15:43:05] Transferring 150Å(150000000u64) to the new delegator withdrawal address...
[2024-06-10 15:43:05]    
[2024-06-10 15:43:05]    
[2024-06-10 15:43:05] BEGIN transfer_public to monadicus_delegator_withdraw 
[2024-06-10 15:43:05]    
[2024-06-10 15:43:05] Balance before transfer: 0Å (0)
[2024-06-10 15:43:05] Transferring 150Å (150000000u64)  
[2024-06-10 15:43:05]   From Private Key:  APrivateKey1zkp8ib2ZLsTSXxEPfwQ89ivgxNzLQ3yjjK2Hpdyc4JadHF9
[2024-06-10 15:43:05]         To Address:  aleo13re02lya0suh3tlau3303xvjkjnscfqhwy7dzs8t7xnzlrkzkypsaf3fka ...
[2024-06-10 15:43:05]    
[2024-06-10 15:43:11] Executed transfer_public 150Å (150000000u64) to aleo13re02lya0suh3tlau3303xvjkjnscfqhwy7dzs8t7xnzlrkzkypsaf3fka
[2024-06-10 15:43:11]   monadicus_delegator_withdraw Transaction:  at1wte48ave9kwqq4dvzye0z48lfl8cfntjg7s9tlfz5tg536jn059q2auce8 
[2024-06-10 15:43:11] Waiting for the transfer to complete...
[2024-06-10 15:43:17] Confirmed balance of 150Å in address aleo13re02lya0suh3tlau3303xvjkjnscfqhwy7dzs8t7xnzlrkzkypsaf3fka
[2024-06-10 15:43:17] Transfer confirmed on-chain.
[2024-06-10 15:43:17] END Transfer to monadicus_delegator_withdraw 
[2024-06-10 15:43:17] Transfered additional 150Å (150000000u64) to delegator withdrawal address aleo13re02lya0suh3tlau3303xvjkjnscfqhwy7dzs8t7xnzlrkzkypsaf3fka
```

Now the delegator bonds to the validator address.

```
[2024-06-10 15:43:17] Executing the bond_public command...
[2024-06-10 15:43:17]    
[2024-06-10 15:43:17]    
[2024-06-10 15:43:17] BEGIN bond_public to monadicus 
[2024-06-10 15:43:17]    
[2024-06-10 15:43:17] Delegators's bonded balance before transfer: 0Å (0)
[2024-06-10 15:43:17]   Delegating 10,000,000Å (10000000000000u64) to Validator monadicus 
[2024-06-10 15:43:17]      From Private Key:  APrivateKey1zkp9q8yK29Bvr18AvXzAzQaXqtUyQTFoCHyMvbhSVeREnoa
[2024-06-10 15:43:17]   .        To Address:  aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w
[2024-06-10 15:43:17]    
[2024-06-10 15:43:23] Executed bond_public 10000000000000u64 to aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w
[2024-06-10 15:43:23]   monadicus Transaction:  at13mtf5ta3y74g0m2ycugm3sa3z7pxeusv2x2cfxq37m0efzqfq59qfafvw0 
[2024-06-10 15:43:23] Waiting for the bonding to complete...
[2024-06-10 15:43:27] Confirmed balance of 10000000000000 in address aleo13re02lya0suh3tlau3303xvjkjnscfqhwy7dzs8t7xnzlrkzkypsaf3fka
[2024-06-10 15:43:27]     Transaction confirmed on-chain.
[2024-06-10 15:43:27] END bond_public to monadicus 
```

At this point, everything is complete.  All accounts have been credited and the delegator has bonded to the validator.  Now it's up to the operator to make sure all accounts are archived along with the audit logs showing the transactions.

```
[2024-06-10 15:43:27]  
[2024-06-10 15:43:27] IMPORTANT!   Do not lose the key files in ./accounts!  Back them up. 
[2024-06-10 15:43:27]  
[2024-06-10 15:43:27] TYPE                | VALUE                                                               | BALANCE 
[2024-06-10 15:43:27] ---------------------------------------------------------------------------------------------------------------
[2024-06-10 15:43:27]  Funding Address    | aleo1r8a69q9z0v67t2w4ut4zamavyr09qr43vk7f584q6wpymg5qvg8scmerq8 | 999,915,839.831762Å (999915839831762) 
[2024-06-10 15:43:27]  Delegator Address  | aleo1jslffusy3mfz83smu04vpezs3uzaasrxy5tcupzg69h0cnryac9qe5f5j4 | 10,000,150Å (10000150000000) 
[2024-06-10 15:43:27]  Withdraw Address   | aleo13re02lya0suh3tlau3303xvjkjnscfqhwy7dzs8t7xnzlrkzkypsaf3fka | 150Å (150000000) 
[2024-06-10 15:43:27] ---------------------------------------------------------------------------------------------------------------
[2024-06-10 15:43:27]       Funding Private Key:  APrivateKey1zkp8ib2ZLsTSXxEPfwQ89ivgxNzLQ3yjjK2Hpdyc4JadHF9 
[2024-06-10 15:43:27]     Delegator Private Key:  APrivateKey1zkp9q8yK29Bvr18AvXzAzQaXqtUyQTFoCHyMvbhSVeREnoa 
[2024-06-10 15:43:27]      Withdraw Private Key:  APrivateKey1zkp7xaeTFX4zcuhD5xs6UBfwdk9MVUXabZJkuN9EKU4Q7oW 
[2024-06-10 15:43:27] ---------------------------------------------------------------------------------------------------------------
[2024-06-10 15:43:27]  Transactions generated and logged: 
[2024-06-10 15:43:27]         Funding Transaction: at1kzc4p8mpeuwlgnxvnr7wsdc83pmmz4hvdgr52n2r3r9nnmemrsfq8nmpcn 
[2024-06-10 15:43:27]             Fee Transaction: at1tqy9yyf6gutd6djmeyu2lwgpculput24lxzdwxq37ugphgqcnqgsf3rw2e 
[2024-06-10 15:43:27]    Withdraw Fee Transaction: at1wte48ave9kwqq4dvzye0z48lfl8cfntjg7s9tlfz5tg536jn059q2auce8 
[2024-06-10 15:43:27]     bond_public Transaction: at13mtf5ta3y74g0m2ycugm3sa3z7pxeusv2x2cfxq37m0efzqfq59qfafvw0 
[2024-06-10 15:43:27]  
[2024-06-10 15:43:27]              Delegator Key in: ./accounts/monadicus_delegate.key
[2024-06-10 15:43:27]     Delegator Withdraw Key in: ./accounts/monadicus_delegate_withdraw.key
[2024-06-10 15:43:27]  
[2024-06-10 15:43:27]     Delegated 10,000,000Å to:  monadicus
[2024-06-10 15:43:27]         Validator Address: aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w
[2024-06-10 15:43:27]  
[2024-06-10 15:43:27]  Godspeed.
```

After this script has been executed, the Foundation should notify the validator team that their validator address has received the bonding funds along with the additional convenience fees.

## Validator Entity Bonding Scripts

### The `bond_validator.sh` Script

See:  [`bond_validator.sh`](../scripts/bond_validator.sh)

Once a validator has been delegated or owns 10 million or more Aleo credits, to enter the validator committee, the validator must bond at least 10 million credits to thier validator address.  


In the example below, the key and addresses are only examples.  Do not use these keys as they are fake.

Example:

``` 
$ ./bond_validator.sh \
    APrivateKey1zkpHawWywic4aEHCN9cexUA1trb7voc23fXe2vH8DrfonES \      # The private key for the validator node
    aleo1rzq3lwwd4ycdqm3y5h9pet2n0rn4wmuagmgsmfhp48nrcl0mx5gq6g480s \  # The public address of the validator node (used for balance verification)
    aleo1cvln9yys2hwlptq3sjc5kv5ugvcjxsq5nap6gq4r77ev8wv6859qh839ml \  # The withdrawal address to be used when unbonding
    10000000000000u64  \                                               # 10_000_000 Aleo Credits in microcredits 
    100u8 \                                                            # The percent (0-100) of the earned commission the validator witholds
    monadicus \                                                        # The one-word unique name for the validator
```


## Convenience Scripts

All of the actions contained in the scripts for this project are implemented in `bash` functions defined in `./scripts/environment.sh`.  All scripts source `./scripts/environment.sh` to include required functionality.  Essentially, each script is a wrapper around a function defined there.  Below is a list of convenience scripts to help the operator verify and test that transactions are successful, to check balances before hand, and also to do simple conversions like converting microcredits to credits with formatting.

### The `get_balance.sh` Script

See:  [`get_balance.sh`](../scripts/get_balance.sh)

This script fetches and prints the balance for any Aleo address.  

Example:  

```
 $ ./get_balance.sh aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w
75000000000
```

One nice trick is to pass the output of this script to the `to_credits.sh` script to format the output as human-readable:

```
 $ ./to_credits.sh $(./get_balance.sh aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w)
75,000Å
```

### The `get_delegated.sh` Script

See:  [`get_delegated.sh`](../scripts/get_delegated.sh)

This script checks how much a validator address has received in delegations from other accounts.  Once the Foundation has run the `fund_and_bond_delegator.sh` script, the validator will have received a delegation of the amount specified (usually at least 10mil Aleo credits)

Example:

```
$ ./get_delegated.sh aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w 
"10000000000000u64"
```

Or, again, using the convenience script to convert to a human readable form of Aleo credits:

``` 
$ ./to_credits.sh $(./get_delegated.sh aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w)
10,000,000Å
```

### The `get_mapping.sh` Script

See:  [`get_mapping.sh`](../scripts/get_mapping.sh)

### The `get_bonded_amount.sh` Script

See:  [`get_bonded_amount.sh`](../scripts/get_bonded_amount.sh)

Fetches the amount a validator with a specific has bonded to their validator address.

### The `new_account.sh` Script

See:  [`new_account.sh`](../scripts/new_account.sh)

This script creates a new account using the name argument to create and log the new account in a file, `./accounts/$NAME.key`.  Anytime this script is run using the same name, it will append a set of key, address, and view key to the log file for that name.

Example:

```
 $ ./new_account.sh frank
[2024-06-10 15:01:13]   
[2024-06-10 15:01:13]        TYPE | VALUE:
[2024-06-10 15:01:13] ------------------------------------------------------------------------
[2024-06-10 15:01:13]  Private Key | APrivateKey1zkpCsNcH12LgoPeryQ1QKmRpZ8y9p2di7z6bontKB71TnFs
[2024-06-10 15:01:13]     View Key | AViewKey1twMdWYs5wNxQMb7mHfChbak28ePY8dCuhEVygpE9q4vu
[2024-06-10 15:01:13]      Address | aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w
```

Output appeneded to `./accounts/frank.key`

### The `transfer_public.sh` Script

See:  [`transfer_public.sh`](../scripts/transfer_public.sh)

Transfers microcredits in the form of `123456789u64` to an address.  This script also appends to a log file in a directory created under the directory where this script is executed, `./transfers/$NAME_transfers.log`.  

The execution of the transfer is confirmed on-chain by checking that the balance of the target address increases by at least the amount of the transfer.  

Example:

```
$ ./transfer_public.sh APrivateKey1zkp8ib2ZLsTSXxEPfwQ89ivgxNzLQ3yjjK2Hpdyc4JadHF9 \      # The private key of the source account for the credits
                     aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w \  # The target address
                     25000000000u64 \                                                   # Number of microcredits (must have the `u64` suffix)
                     monadicus                                                          # One-word name for target.  Used for logging transaction.
```

Output:

```
[2024-06-10 15:04:58]    
[2024-06-10 15:04:58]    
[2024-06-10 15:04:58] BEGIN transfer_public to monadicus 
[2024-06-10 15:04:58]    
[2024-06-10 15:04:58] Balance before transfer: 0Å (0)
[2024-06-10 15:04:58] Transferring 25,000Å (25000000000u64)  
[2024-06-10 15:04:58]   From Private Key:  APrivateKey1zkp8ib2ZLsTSXxEPfwQ89ivgxNzLQ3yjjK2Hpdyc4JadHF9
[2024-06-10 15:04:58]         To Address:  aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w ...
[2024-06-10 15:04:58]    
[2024-06-10 15:05:04] Executed transfer_public 25,000Å (25000000000u64) to aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w
[2024-06-10 15:05:04]   monadicus Transaction:  at1ljzkaspfj29puzqjgqcrvfsuzxde37z2g9cawg209gm0zfk88cyq023gwm 
[2024-06-10 15:05:04] Waiting for the transfer to complete...
[2024-06-10 15:05:09] Confirmed balance of 25,000Å in address aleo1272p6f37vm3gdaahqs06crwz6xv2y7rtex3luyetghf9zchjvgxqv28u2w
[2024-06-10 15:05:09] Transfer confirmed on-chain.
[2024-06-10 15:05:09] END Transfer to monadicus 
```

## Validator Entity Bonding Scripts

### The `bond_validator.sh` Script

See:  [`bond_validator.sh`](../scripts/bond_validator.sh)


## Suggested Validator `snarkOS` Management Scripts






