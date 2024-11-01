## DepositHandler
The problem with scammers in the Encode community increases quite fast, and unfortunately more and more community members receive scam messages in Discord and email. Our group realized that the current Encode depositing mechanism(sending a Polygon address via email to do a USDC deposit) is really unsafe for users.\
So our team decided to create a DepositHandler protocol, which can significantly decrease the problem of scams. We decided to minimize user interaction with external resources like email, and allow him to do a deposit on-chain through our DApp. User just needs to connect his wallet, select a bootcamp, deposit USDC, and once successfully finish a bootcamp, he will be allowed to withdraw his deposit back.

## Technology Stack & Tools
- [Solidity](https://docs.soliditylang.org/en/v0.8.28/) (Smart Contracts/Tests/Scripts)
- [Foundry](https://book.getfoundry.sh/) (Development Framework)

## Setting Up The Project
1. Clone/Download the Repository:
```shell
git clone https://github.com/ohMySol/EncodeProject.git
```

2. Install Dependencies:
```shell
$ forge install
```

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Deploy

```shell
$ forge script script/DepositHandler.s.sol:DepositHandlerScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```