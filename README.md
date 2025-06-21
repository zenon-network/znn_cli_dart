# Zenon CLI Tool

The Zenon CLI tool is a comprehensive command-line interface designed to interact with Alphanet - Network of Momentum Phase 1. It provides full functionality for wallet management, token transfers, staking, node operations, and smart contract interactions on the Zenon Network.

## Table of Contents

- [Installation](#installation)
- [Building from Source](#building-from-source)
- [Global Options and Flags](#global-options-and-flags)
- [Commands Summary](#commands-summary)
- [Command Reference](#command-reference)
  - [General Commands](#general-commands)
  - [Wallet Commands](#wallet-commands)
  - [Stats Commands](#stats-commands)
  - [Plasma Commands](#plasma-commands)
  - [Sentinel Commands](#sentinel-commands)
  - [Staking Commands](#staking-commands)
  - [Pillar Commands](#pillar-commands)
  - [Token Commands](#token-commands)
  - [Accelerator-Z Commands](#accelerator-z-commands)
  - [Spork Commands](#spork-commands)
  - [HTLC Commands](#htlc-commands)
  - [Bridge Commands](#bridge-commands)
  - [Liquidity Commands](#liquidity-commands)
  - [Orchestrator Commands](#orchestrator-commands)

## Installation

Download and extract the [latest version](https://github.com/zenon-network/znn_cli_dart/releases/).

**Important:** All required dynamic libraries are included in the `build/` folder. When moving the `znn-cli` binary, ensure you also move the accompanying libraries.

## Building from Source

### Prerequisites
- Dart SDK installed on your system
- Make (for using the provided Makefile)

### Build Commands

```bash
# Clone the repository
git clone https://github.com/zenon-network/znn_cli_dart.git
cd znn_cli_dart

# Install dependencies
dart pub get

# Build for Windows
make windows

# Build for Linux
make linux
```

The compiled binary will be in the `build/` directory along with required native libraries.

## Global Options and Flags

### Options
- `-u, --url` - WebSocket znnd connection URL (default: `ws://127.0.0.1:35998`)
- `-p, --passphrase` - Passphrase for the keyStore (or enter manually for security)
- `-k, --keyStore` - Select local keyStore (default: available keyStore if only one exists)
- `-i, --index` - Address index (default: `0`)
- `-c, --chain` - Chain identifier for connected node (default: `1` for mainnet)

### Flags
- `-v, --verbose` - Print detailed information about actions
- `-h, --help` - Display help information
- `-a, --admin` - Display admin functions

## Commands Summary

### General Operations
- `send` - Send tokens to an address
- `receive` - Manually receive transactions
- `receiveAll` - Receive all pending transactions
- `autoreceive` - Automatically receive transactions
- `unreceived` - List pending transactions
- `unconfirmed` - List unconfirmed transactions
- `balance` - Check account balance
- `frontierMomentum` - Display frontier momentum
- `createHash` - Create hash digests
- `version` - Display version information

### Wallet Management
- `wallet.list` - List all wallets
- `wallet.createNew` - Create new wallet
- `wallet.createFromMnemonic` - Create wallet from mnemonic
- `wallet.dumpMnemonic` - Export wallet mnemonic
- `wallet.deriveAddresses` - Derive wallet addresses
- `wallet.export` - Export wallet to file

### Network Stats
- `stats.networkInfo` - Get network information
- `stats.osInfo` - Get operating system information
- `stats.processInfo` - Get process information
- `stats.syncInfo` - Get synchronization status

### Plasma Operations
- `plasma.list` - List plasma fusion entries
- `plasma.get` - Check plasma balance
- `plasma.fuse` - Fuse QSR for plasma
- `plasma.cancel` - Cancel plasma fusion

### Node Operations
- `sentinel.*` - Sentinel node management
- `pillar.*` - Pillar node management

### DeFi Operations
- `stake.*` - Staking management
- `token.*` - Token creation and management
- `bridge.*` - Cross-chain bridge operations
- `liquidity.*` - Liquidity provision
- `htlc.*` - Hash Time-Locked Contracts

### Governance
- `az.*` - Accelerator-Z donations
- `spork.*` - Network upgrade management

## Command Reference

### General Commands

#### send
Send tokens to another address.

**Usage:** `send toAddress amount [ZNN/QSR/ZTS message]`

**Examples:**
```bash
# Send 10 ZNN to an address
znn-cli send z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz 10

# Send 100 QSR to an address
znn-cli send z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz 100 QSR

# Send 50 tokens of a custom ZTS with a message
znn-cli send z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz 50 zts1xxxxxxxxxxxxxxxxxxxxxx "Payment for services"
```

#### receive
Manually receive a specific transaction by its block hash.

**Usage:** `receive blockHash`

**Example:**
```bash
znn-cli receive 3f9609c0542f9fe9b3b9c3080f03d766509abe09e762395eb433288ce740c7f0
```

#### receiveAll
Automatically receive all pending transactions for your address.

**Usage:** `receiveAll`

**Example:**
```bash
znn-cli receiveAll
```

#### autoreceive
Start automatic receiving of transactions (runs continuously).

**Usage:** `autoreceive`

**Example:**
```bash
znn-cli autoreceive
```

#### unreceived
List all unreceived transactions for your address.

**Usage:** `unreceived`

**Example:**
```bash
znn-cli unreceived
```

#### unconfirmed
List all unconfirmed transactions from your address.

**Usage:** `unconfirmed`

**Example:**
```bash
znn-cli unconfirmed
```

#### balance
Check the token balance of any address.

**Usage:** `balance address`

**Example:**
```bash
znn-cli balance z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

#### frontierMomentum
Display the current frontier momentum (latest network block).

**Usage:** `frontierMomentum`

**Example:**
```bash
znn-cli frontierMomentum
```

#### createHash
Create hash digests using SHA3-256 or SHA2-256.

**Usage:** `createHash [hashType preimageLength]`
- `hashType`: 0 for SHA3-256 (default), 1 for SHA2-256
- `preimageLength`: Length in bytes (default: 32)

**Examples:**
```bash
# Create SHA3-256 hash with 32-byte preimage
znn-cli createHash

# Create SHA2-256 hash with 64-byte preimage
znn-cli createHash 1 64
```

#### version
Display CLI and SDK version information.

**Usage:** `version`

**Example:**
```bash
znn-cli version
```

### Wallet Commands

#### wallet.list
List all available keyStore wallets.

**Usage:** `wallet.list`

**Example:**
```bash
znn-cli wallet.list
```

#### wallet.createNew
Create a new wallet with a secure passphrase.

**Usage:** `wallet.createNew passphrase [keyStoreName]`

**Example:**
```bash
znn-cli wallet.createNew "my secure passphrase" myWallet
```

#### wallet.createFromMnemonic
Create a wallet from an existing mnemonic phrase.

**Usage:** `wallet.createFromMnemonic "mnemonic" passphrase [keyStoreName]`

**Example:**
```bash
znn-cli wallet.createFromMnemonic "your twelve word mnemonic phrase goes here ..." "secure passphrase" restoredWallet
```

#### wallet.dumpMnemonic
Export the mnemonic phrase of the current wallet.

**Usage:** `wallet.dumpMnemonic`

**Example:**
```bash
znn-cli wallet.dumpMnemonic
```

#### wallet.deriveAddresses
Derive multiple addresses from the current wallet.

**Usage:** `wallet.deriveAddresses start end`

**Example:**
```bash
# Derive addresses from index 0 to 9
znn-cli wallet.deriveAddresses 0 9
```

#### wallet.export
Export wallet to a keyStore file.

**Usage:** `wallet.export filePath`

**Example:**
```bash
znn-cli wallet.export ./backup/my-wallet-backup.json
```

### Stats Commands

#### stats.networkInfo
Display detailed network information.

**Usage:** `stats.networkInfo`

**Example:**
```bash
znn-cli stats.networkInfo
```

#### stats.osInfo
Display operating system information of the connected node.

**Usage:** `stats.osInfo`

**Example:**
```bash
znn-cli stats.osInfo
```

#### stats.processInfo
Display process information of the connected node.

**Usage:** `stats.processInfo`

**Example:**
```bash
znn-cli stats.processInfo
```

#### stats.syncInfo
Display blockchain synchronization status.

**Usage:** `stats.syncInfo`

**Example:**
```bash
znn-cli stats.syncInfo
```

### Plasma Commands

#### plasma.list
List all plasma fusion entries with pagination.

**Usage:** `plasma.list [pageIndex pageSize]`

**Example:**
```bash
# List first page with default size
znn-cli plasma.list

# List second page with 50 entries per page
znn-cli plasma.list 1 50
```

#### plasma.get
Display plasma balance for a specific address.

**Usage:** `plasma.get address`

**Example:**
```bash
znn-cli plasma.get z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

#### plasma.fuse
Fuse QSR to generate plasma for an address.

**Usage:** `plasma.fuse toAddress amount`

**Example:**
```bash
# Fuse 100 QSR to generate plasma for your address
znn-cli plasma.fuse z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz 100
```

#### plasma.cancel
Cancel a plasma fusion entry and recover QSR.

**Usage:** `plasma.cancel id`

**Example:**
```bash
znn-cli plasma.cancel 3f9609c0542f9fe9b3b9c3080f03d766509abe09e762395eb433288ce740c7f0
```

### Sentinel Commands

#### sentinel.list
List all active sentinels in the network.

**Usage:** `sentinel.list`

**Example:**
```bash
znn-cli sentinel.list
```

#### sentinel.register
Register a new sentinel node (requires 5,000 ZNN collateral).

**Usage:** `sentinel.register`

**Example:**
```bash
znn-cli sentinel.register
```

#### sentinel.revoke
Revoke your sentinel and recover collateral.

**Usage:** `sentinel.revoke`

**Example:**
```bash
znn-cli sentinel.revoke
```

#### sentinel.collect
Collect sentinel rewards.

**Usage:** `sentinel.collect`

**Example:**
```bash
znn-cli sentinel.collect
```

#### sentinel.depositQsr
Deposit QSR to the sentinel contract.

**Usage:** `sentinel.depositQsr`

**Example:**
```bash
znn-cli sentinel.depositQsr
```

#### sentinel.withdrawQsr
Withdraw deposited QSR from the sentinel contract.

**Usage:** `sentinel.withdrawQsr`

**Example:**
```bash
znn-cli sentinel.withdrawQsr
```

### Staking Commands

#### stake.list
List all active stakes with pagination.

**Usage:** `stake.list [pageIndex pageSize]`

**Example:**
```bash
# List first page of stakes
znn-cli stake.list

# List third page with 100 entries
znn-cli stake.list 2 100
```

#### stake.register
Create a new stake entry.

**Usage:** `stake.register amount duration`
- `amount`: Amount of ZNN to stake
- `duration`: Lock duration in months (1-12)

**Example:**
```bash
# Stake 1000 ZNN for 6 months
znn-cli stake.register 1000 6
```

#### stake.revoke
Cancel a stake and recover ZNN (after lock period).

**Usage:** `stake.revoke id`

**Example:**
```bash
znn-cli stake.revoke a3f9609c0542f9fe9b3b9c3080f03d766509abe09e762395eb433288ce740c7f0
```

#### stake.collect
Collect staking rewards.

**Usage:** `stake.collect`

**Example:**
```bash
znn-cli stake.collect
```

### Pillar Commands

#### pillar.list
List all pillars in the network.

**Usage:** `pillar.list`

**Example:**
```bash
znn-cli pillar.list
```

#### pillar.register
Register a new pillar (requires 15,000 ZNN collateral).

**Usage:** `pillar.register name producerAddress rewardAddress giveBlockRewardPercentage giveDelegateRewardPercentage`

**Example:**
```bash
znn-cli pillar.register MyPillar z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz 0 10
```

#### pillar.revoke
Revoke your pillar and recover collateral.

**Usage:** `pillar.revoke name`

**Example:**
```bash
znn-cli pillar.revoke MyPillar
```

#### pillar.delegate
Delegate your weight to a pillar.

**Usage:** `pillar.delegate name`

**Example:**
```bash
znn-cli pillar.delegate MyFavoritePillar
```

#### pillar.undelegate
Remove delegation from current pillar.

**Usage:** `pillar.undelegate`

**Example:**
```bash
znn-cli pillar.undelegate
```

#### pillar.collect
Collect pillar rewards.

**Usage:** `pillar.collect`

**Example:**
```bash
znn-cli pillar.collect
```

#### pillar.depositQsr
Deposit QSR to the pillar contract.

**Usage:** `pillar.depositQsr`

**Example:**
```bash
znn-cli pillar.depositQsr
```

#### pillar.withdrawQsr
Withdraw deposited QSR from the pillar contract.

**Usage:** `pillar.withdrawQsr`

**Example:**
```bash
znn-cli pillar.withdrawQsr
```

### Token Commands

#### token.list
List all tokens with pagination.

**Usage:** `token.list [pageIndex pageSize]`

**Example:**
```bash
# List first page of tokens
znn-cli token.list

# List second page with 50 tokens
znn-cli token.list 1 50
```

#### token.getByStandard
Get token information by its ZTS address.

**Usage:** `token.getByStandard tokenStandard`

**Example:**
```bash
znn-cli token.getByStandard zts1znnxxxxxxxxxxxxx9z4ulx
```

#### token.getByOwner
List all tokens owned by an address.

**Usage:** `token.getByOwner ownerAddress`

**Example:**
```bash
znn-cli token.getByOwner z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

#### token.issue
Create a new ZTS token.

**Usage:** `token.issue name symbol domain totalSupply maxSupply decimals isMintable isBurnable isUtility`

**Example:**
```bash
# Create a mintable, burnable token with 1M supply
znn-cli token.issue MyToken MTK mytoken.com 1000000 10000000 8 true true false
```

#### token.mint
Mint additional tokens (if token is mintable).

**Usage:** `token.mint tokenStandard amount receiveAddress`

**Example:**
```bash
znn-cli token.mint zts1znnxxxxxxxxxxxxx9z4ulx 10000 z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

#### token.burn
Burn tokens to reduce supply.

**Usage:** `token.burn tokenStandard amount`

**Example:**
```bash
znn-cli token.burn zts1znnxxxxxxxxxxxxx9z4ulx 5000
```

#### token.transferOwnership
Transfer token ownership to another address.

**Usage:** `token.transferOwnership tokenStandard newOwnerAddress`

**Example:**
```bash
znn-cli token.transferOwnership zts1znnxxxxxxxxxxxxx9z4ulx z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

#### token.disableMint
Permanently disable minting for a token.

**Usage:** `token.disableMint tokenStandard`

**Example:**
```bash
znn-cli token.disableMint zts1znnxxxxxxxxxxxxx9z4ulx
```

### Accelerator-Z Commands

#### az.donate
Donate ZNN or QSR to the Accelerator-Z fund.

**Usage:** `az.donate amount ZNN/QSR`

**Examples:**
```bash
# Donate 100 ZNN
znn-cli az.donate 100 ZNN

# Donate 1000 QSR
znn-cli az.donate 1000 QSR
```

### Spork Commands

#### spork.list
List all sporks (network upgrades).

**Usage:** `spork.list [pageIndex pageSize]`

**Example:**
```bash
znn-cli spork.list
```

#### spork.create
Create a new spork proposal (admin only).

**Usage:** `spork.create name description`

**Example:**
```bash
znn-cli spork.create "UpgradeV2" "Protocol upgrade to version 2.0"
```

#### spork.activate
Activate a spork (admin only).

**Usage:** `spork.activate id`

**Example:**
```bash
znn-cli spork.activate 3f9609c0542f9fe9b3b9c3080f03d766509abe09e762395eb433288ce740c7f0
```

### HTLC Commands

#### htlc.create
Create a Hash Time-Locked Contract.

**Usage:** `htlc.create hashLockedAddress tokenStandard amount expirationTime [hashType hashLock]`
- `expirationTime`: Hours until expiration
- `hashType`: 0 for SHA3-256, 1 for SHA2-256

**Example:**
```bash
# Create HTLC for 100 ZNN expiring in 24 hours
znn-cli htlc.create z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz ZNN 100 24
```

#### htlc.unlock
Unlock an HTLC with the preimage.

**Usage:** `htlc.unlock id preimage`

**Example:**
```bash
znn-cli htlc.unlock 3f9609c0542f9fe9b3b9c3080f03d766509abe09e762395eb433288ce740c7f0 "secret_preimage"
```

#### htlc.reclaim
Reclaim funds from an expired HTLC.

**Usage:** `htlc.reclaim id`

**Example:**
```bash
znn-cli htlc.reclaim 3f9609c0542f9fe9b3b9c3080f03d766509abe09e762395eb433288ce740c7f0
```

#### htlc.get
Display HTLC details.

**Usage:** `htlc.get id`

**Example:**
```bash
znn-cli htlc.get 3f9609c0542f9fe9b3b9c3080f03d766509abe09e762395eb433288ce740c7f0
```

#### htlc.inspect
Inspect HTLC creation transaction.

**Usage:** `htlc.inspect blockHash`

**Example:**
```bash
znn-cli htlc.inspect 3f9609c0542f9fe9b3b9c3080f03d766509abe09e762395eb433288ce740c7f0
```

#### htlc.getProxyStatus
Check proxy unlock permission status.

**Usage:** `htlc.getProxyStatus address`

**Example:**
```bash
znn-cli htlc.getProxyStatus z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

#### htlc.denyProxy
Deny proxy unlock permission.

**Usage:** `htlc.denyProxy`

**Example:**
```bash
znn-cli htlc.denyProxy
```

#### htlc.allowProxy
Allow proxy unlock permission.

**Usage:** `htlc.allowProxy`

**Example:**
```bash
znn-cli htlc.allowProxy
```

#### htlc.monitor
Monitor an HTLC for automatic reclaim or preimage reveal.

**Usage:** `htlc.monitor id`

**Example:**
```bash
znn-cli htlc.monitor 3f9609c0542f9fe9b3b9c3080f03d766509abe09e762395eb433288ce740c7f0
```

### Bridge Commands

#### Bridge Info Commands

##### bridge.info
Get general bridge information.

**Usage:** `bridge.info`

**Example:**
```bash
znn-cli bridge.info
```

##### bridge.security
Get bridge security information.

**Usage:** `bridge.security`

**Example:**
```bash
znn-cli bridge.security
```

##### bridge.timeChallenges
List all bridge time challenges.

**Usage:** `bridge.timeChallenges`

**Example:**
```bash
znn-cli bridge.timeChallenges
```

##### bridge.orchestratorInfo
Get orchestrator information.

**Usage:** `bridge.orchestratorInfo`

**Example:**
```bash
znn-cli bridge.orchestratorInfo
```

##### bridge.fees
Display accumulated wrapping fees.

**Usage:** `bridge.fees [tokenStandard]`

**Example:**
```bash
# Show fees for all tokens
znn-cli bridge.fees

# Show fees for specific token
znn-cli bridge.fees ZNN
```

#### Bridge Network Commands

##### bridge.network.list
List all configured bridge networks.

**Usage:** `bridge.network.list`

**Example:**
```bash
znn-cli bridge.network.list
```

##### bridge.network.get
Get network information by class and chain ID.

**Usage:** `bridge.network.get networkClass chainId`

**Example:**
```bash
znn-cli bridge.network.get 2 1
```

#### Bridge Wrap Commands

##### bridge.wrap.token
Wrap tokens to another network.

**Usage:** `bridge.wrap.token networkClass chainId toAddress amount tokenStandard`

**Example:**
```bash
# Wrap 100 ZNN to Ethereum
znn-cli bridge.wrap.token 2 1 0x742d35Cc6634C0532925a3b844Bc9e7595f2bd8e 100 ZNN
```

##### bridge.wrap.list
List all wrap requests.

**Usage:** `bridge.wrap.list`

**Example:**
```bash
znn-cli bridge.wrap.list
```

##### bridge.wrap.listByAddress
List wrap requests for a specific address.

**Usage:** `bridge.wrap.listByAddress address [networkClass chainId]`

**Example:**
```bash
znn-cli bridge.wrap.listByAddress z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

##### bridge.wrap.listUnsigned
List all unsigned wrap requests.

**Usage:** `bridge.wrap.listUnsigned`

**Example:**
```bash
znn-cli bridge.wrap.listUnsigned
```

##### bridge.wrap.get
Get wrap request details by ID.

**Usage:** `bridge.wrap.get id`

**Example:**
```bash
znn-cli bridge.wrap.get 3f9609c0542f9fe9b3b9c3080f03d766509abe09e762395eb433288ce740c7f0
```

#### Bridge Unwrap Commands

##### bridge.unwrap.redeem
Redeem unwrapped tokens.

**Usage:** `bridge.unwrap.redeem transactionHash logIndex`

**Example:**
```bash
znn-cli bridge.unwrap.redeem 0x5d3a536E4D6DbD6114cc4Ebb4bB5f7f28Df4C055 0
```

##### bridge.unwrap.redeemAll
Redeem all pending unwrap requests.

**Usage:** `bridge.unwrap.redeemAll [forAllAddresses]`

**Examples:**
```bash
# Redeem your own unwraps
znn-cli bridge.unwrap.redeemAll

# Redeem all unwraps (any address)
znn-cli bridge.unwrap.redeemAll true
```

##### bridge.unwrap.list
List all unwrap requests.

**Usage:** `bridge.unwrap.list`

**Example:**
```bash
znn-cli bridge.unwrap.list
```

##### bridge.unwrap.listByAddress
List unwrap requests for an address.

**Usage:** `bridge.unwrap.listByAddress toAddress`

**Example:**
```bash
znn-cli bridge.unwrap.listByAddress z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

##### bridge.unwrap.listUnredeemed
List unredeemed unwrap requests.

**Usage:** `bridge.unwrap.listUnredeemed [toAddress]`

**Example:**
```bash
# List all unredeemed
znn-cli bridge.unwrap.listUnredeemed

# List for specific address
znn-cli bridge.unwrap.listUnredeemed z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

##### bridge.unwrap.get
Get unwrap request details.

**Usage:** `bridge.unwrap.get transactionHash logIndex`

**Example:**
```bash
znn-cli bridge.unwrap.get 0x5d3a536E4D6DbD6114cc4Ebb4bB5f7f28Df4C055 0
```

#### Bridge Guardian Commands

##### bridge.guardian.proposeAdmin
Propose new admin in emergency mode.

**Usage:** `bridge.guardian.proposeAdmin address`

**Example:**
```bash
znn-cli bridge.guardian.proposeAdmin z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

#### Bridge Admin Commands

##### bridge.admin.emergency
Activate emergency mode.

**Usage:** `bridge.admin.emergency`

**Example:**
```bash
znn-cli bridge.admin.emergency
```

##### bridge.admin.halt
Halt bridge operations.

**Usage:** `bridge.admin.halt`

**Example:**
```bash
znn-cli bridge.admin.halt
```

##### bridge.admin.unhalt
Resume bridge operations.

**Usage:** `bridge.admin.unhalt`

**Example:**
```bash
znn-cli bridge.admin.unhalt
```

##### bridge.admin.enableKeyGen
Enable TSS key generation.

**Usage:** `bridge.admin.enableKeyGen`

**Example:**
```bash
znn-cli bridge.admin.enableKeyGen
```

##### bridge.admin.disableKeyGen
Disable TSS key generation.

**Usage:** `bridge.admin.disableKeyGen`

**Example:**
```bash
znn-cli bridge.admin.disableKeyGen
```

##### bridge.admin.setTokenPair
Configure a bridgeable token pair.

**Usage:** `bridge.admin.setTokenPair networkClass chainId tokenStandard tokenAddress bridgeable redeemable owned minAmount feePercentage redeemDelay metadata`

**Example:**
```bash
znn-cli bridge.admin.setTokenPair 2 1 ZNN 0x5FbDB2315678afecb367f032d93F642f64180aa3 true true true 1 100 500 "{}"
```

##### bridge.admin.removeTokenPair
Remove a token pair.

**Usage:** `bridge.admin.removeTokenPair networkClass chainId tokenStandard tokenAddress`

**Example:**
```bash
znn-cli bridge.admin.removeTokenPair 2 1 ZNN 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

##### bridge.admin.revokeUnwrapRequest
Revoke an unwrap request.

**Usage:** `bridge.admin.revokeUnwrapRequest transactionHash logIndex`

**Example:**
```bash
znn-cli bridge.admin.revokeUnwrapRequest 0x5d3a536E4D6DbD6114cc4Ebb4bB5f7f28Df4C055 0
```

##### bridge.admin.nominateGuardians
Nominate bridge guardians.

**Usage:** `bridge.admin.nominateGuardians address1 address2 ... addressN`

**Example:**
```bash
znn-cli bridge.admin.nominateGuardians z1address1 z1address2 z1address3
```

##### bridge.admin.changeAdmin
Change bridge administrator.

**Usage:** `bridge.admin.changeAdmin address`

**Example:**
```bash
znn-cli bridge.admin.changeAdmin z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

##### bridge.admin.setMetadata
Set bridge metadata.

**Usage:** `bridge.admin.setMetadata metadata`

**Example:**
```bash
znn-cli bridge.admin.setMetadata '{"version":"1.0","description":"Zenon Bridge"}'
```

##### bridge.admin.setOrchestratorInfo
Configure orchestrator parameters.

**Usage:** `bridge.admin.setOrchestratorInfo windowSize keyGenThreshold confirmationsToFinality estimatedMomentumTime`

**Example:**
```bash
znn-cli bridge.admin.setOrchestratorInfo 64 30 2 6
```

##### bridge.admin.setNetwork
Configure a bridge network.

**Usage:** `bridge.admin.setNetwork networkClass chainId name contractAddress metadata`

**Example:**
```bash
znn-cli bridge.admin.setNetwork 2 1 "Ethereum Mainnet" 0x5FbDB2315678afecb367f032d93F642f64180aa3 "{}"
```

##### bridge.admin.removeNetwork
Remove a bridge network.

**Usage:** `bridge.admin.removeNetwork networkClass chainId`

**Example:**
```bash
znn-cli bridge.admin.removeNetwork 2 1
```

##### bridge.admin.setNetworkMetadata
Update network metadata.

**Usage:** `bridge.admin.setNetworkMetadata networkClass chainId metadata`

**Example:**
```bash
znn-cli bridge.admin.setNetworkMetadata 2 1 '{"updated":true}'
```

### Liquidity Commands

#### Liquidity Info Commands

##### liquidity.info
Get liquidity contract information.

**Usage:** `liquidity.info`

**Example:**
```bash
znn-cli liquidity.info
```

##### liquidity.security
Get liquidity security information.

**Usage:** `liquidity.security`

**Example:**
```bash
znn-cli liquidity.security
```

##### liquidity.timeChallenges
List liquidity time challenges.

**Usage:** `liquidity.timeChallenges`

**Example:**
```bash
znn-cli liquidity.timeChallenges
```

##### liquidity.getRewardTotal
Get total rewards earned by an address.

**Usage:** `liquidity.getRewardTotal address`

**Example:**
```bash
znn-cli liquidity.getRewardTotal z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

##### liquidity.getStakeEntries
List all stake entries for an address.

**Usage:** `liquidity.getStakeEntries address`

**Example:**
```bash
znn-cli liquidity.getStakeEntries z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

##### liquidity.getUncollectedReward
Display uncollected rewards.

**Usage:** `liquidity.getUncollectedReward address`

**Example:**
```bash
znn-cli liquidity.getUncollectedReward z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

#### Liquidity Staking Commands

##### liquidity.stake
Stake LP tokens for rewards.

**Usage:** `liquidity.stake duration amount tokenStandard`
- `duration`: Lock period in months

**Example:**
```bash
# Stake 1000 LP tokens for 3 months
znn-cli liquidity.stake 3 1000 zts1lptoken
```

##### liquidity.cancelStake
Cancel an unlocked stake.

**Usage:** `liquidity.cancelStake id`

**Example:**
```bash
znn-cli liquidity.cancelStake 3f9609c0542f9fe9b3b9c3080f03d766509abe09e762395eb433288ce740c7f0
```

##### liquidity.collectRewards
Collect earned liquidity rewards.

**Usage:** `liquidity.collectRewards`

**Example:**
```bash
znn-cli liquidity.collectRewards
```

#### Liquidity Guardian Commands

##### liquidity.guardian.proposeAdmin
Propose new admin in emergency mode.

**Usage:** `liquidity.guardian.proposeAdmin address`

**Example:**
```bash
znn-cli liquidity.guardian.proposeAdmin z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

#### Liquidity Admin Commands

##### liquidity.admin.emergency
Activate emergency mode.

**Usage:** `liquidity.admin.emergency`

**Example:**
```bash
znn-cli liquidity.admin.emergency
```

##### liquidity.admin.halt
Halt liquidity operations.

**Usage:** `liquidity.admin.halt`

**Example:**
```bash
znn-cli liquidity.admin.halt
```

##### liquidity.admin.unhalt
Resume liquidity operations.

**Usage:** `liquidity.admin.unhalt`

**Example:**
```bash
znn-cli liquidity.admin.unhalt
```

##### liquidity.admin.changeAdmin
Change liquidity administrator.

**Usage:** `liquidity.admin.changeAdmin address`

**Example:**
```bash
znn-cli liquidity.admin.changeAdmin z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz
```

##### liquidity.admin.nominateGuardians
Nominate liquidity guardians.

**Usage:** `liquidity.admin.nominateGuardians address1 address2 ... addressN`

**Example:**
```bash
znn-cli liquidity.admin.nominateGuardians z1address1 z1address2 z1address3
```

##### liquidity.admin.unlockStakeEntries
Unlock all stakes for a token.

**Usage:** `liquidity.admin.unlockStakeEntries tokenStandard`

**Example:**
```bash
znn-cli liquidity.admin.unlockStakeEntries zts1lptoken
```

##### liquidity.admin.setAdditionalReward
Set additional reward percentages.

**Usage:** `liquidity.admin.setAdditionalReward znnReward qsrReward`

**Example:**
```bash
znn-cli liquidity.admin.setAdditionalReward 15 20
```

##### liquidity.admin.setTokenTuple
Configure stakeable token tuples.

**Usage:** `liquidity.admin.setTokenTuple tokenTuples`

**Example:**
```bash
znn-cli liquidity.admin.setTokenTuple '[["ZNN","QSR","zts1lptoken1",1,100,5000]]'
```

### Orchestrator Commands

**Note:** Orchestrator functions are currently unsupported in the CLI.

- `orchestrator.changePubKey` - Change orchestrator public key
- `orchestrator.haltBridge` - Halt bridge via orchestrator
- `orchestrator.updateWrapRequest` - Update wrap request
- `orchestrator.unwrapToken` - Process unwrap as orchestrator

## Tips and Best Practices

1. **Security**: Never share your keyStore files or mnemonic phrases
2. **Backups**: Always backup your wallet before major operations
3. **Gas/Plasma**: Ensure you have enough plasma for transactions (fuse QSR if needed)
4. **Confirmations**: Wait for transactions to be confirmed before assuming success
5. **Addresses**: Always double-check addresses before sending tokens
6. **Testing**: Test commands with small amounts first

## Error Handling

Common errors and solutions:
- `insufficient plasma`: Fuse more QSR using `plasma.fuse`
- `address not found`: Ensure the wallet is unlocked and correct index is used
- `connection refused`: Check that znnd is running and the URL is correct
- `invalid amount`: Ensure amounts are positive numbers with correct decimals

## Support

For additional help:
- Use the `-h` flag with any command for detailed help
- Check the [official documentation](https://docs.zenon.network)
- Join the community channels for support