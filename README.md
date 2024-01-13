
# SupraOracles Assignment
## Overview
### This project includes several smart contracts, each serving a distinct purpose in the blockchain ecosystem. The main contracts are:

**TokenSale**:

- A smart contract facilitating a token sale with presale and public sale phases.
- Implements ERC-20 standard for the project token.
- Allows users to contribute Ether to the sale and receive project tokens in return.
- Handles token distribution, refund in case of sale failure, and other functionalities.

**Decentralized Voting**:

- A decentralized voting system using blockchain technology.
- Allows users to cast votes securely and transparently.
- Implements mechanisms to ensure the integrity and fairness of the voting process.

**TokenSwap**:

- A smart contract enabling the swapping of tokens between users.
- Provides a mechanism for users to exchange one type of token for another.
- Facilitates secure and automated token swaps within the blockchain network.

**Multisig**:

- A multi-signature wallet allowing multiple private keys to authorize transactions.
- Enhances security by requiring multiple signatures for any outgoing transaction.
- Ideal for collaborative management of funds and assets on the blockchain.

## Installation

### Prerequisites
- Foundry (https://book.getfoundry.sh/getting-started/installation)

### To set up the Foundry project, follow these steps:
- Clone the repository.
- Run forge install to install all dependencies.

```bash
forge install
```

- Run forge build to compile the smart contracts.

```bash
forge build
```
***Note:*** *If you encounter any errors, ensure that all dependencies are installed, and the remapping.txt file is accurate.*

### To run tests, use the following command:

```bash
forge test -vvv
```

### Running Scripts

***To execute scripts for specific contracts, follow these instructions***:

- Add an .env file to the project root.
- For TokenSwap and TokenSale, only a single PRIVATE_KEY is required in the .env file.
- For Multisig and Decentralized Voting, multiple private keys and addresses should be added in the following format:

```env
ADDR1 = {Address 1}
PK1 = {Private Key 1}
ADDR2 = {Address 2}
PK2 = {Private Key 2}
ADDR3 = {Address 3}
PK3 = {Private Key 3}
ADDR4 = {Address 4}
PK4 = {Private Key 4}
ADDR5 = {Address 5}
PK5 = {Private Key 5}
ADDR6 = {Address 6}
PK6 = {Private Key 6}
ADDR7 = {Address 7}
PK7 = {Private Key 7}
```
***Note:*** *The number of addresses and private keys can be changed as required but a minimum of 7 are required by default*

### To run any script, use the following command:

```bash
forge script --[path]
```
***Note:*** *Include --rpc-url [url] to simulate on a specific chain, and use --broadcast to actually broadcast the transactions to the blockchain.*
```bash
forge script --[path] --rpc-url [url] --broadcast
```