## DepositHandler
This is a 1st MVP DApp version. This code was thoroughly tested, but it can still have security issues or not been well optimised. All found issues will be solved in the next development iterations.
### Problem we are trying to solve:
The problem with scammers in the Encode community increases quite fast, and unfortunately more and more community members receive scam messages in Discord and Email. Our group realized that the current Encode depositing mechanism(sending a Polygon address via email to do a USDC deposit) is quite an unsafe way for users.\
So our team decided to create a DepositHandler DApp, which can significantly decrease the problem of scams. We decided to minimize users interaction with external resources like email, and allow them to do a deposit on-chain through our DApp. 

### Architecture
![img-alt](https://github.com/ohMySol/encode-deposit-handler-sc/blob/feature/Anton/DepositHandler.jpg?raw=true)

### How does this work?
Project consists from 2 parts: smart contracts and user friendly frontend. In this repo i'll describe only how smart contracts part works.
1. We decided to folow a factory pattern and design our system in the way that we have a factory contract which is responsible for creating bootcamp contracts. This way allow us:
 - Simplify the process of deploying multiple instances of DepositHandler(bootcamp) contract.
 - We separate bootcamp management logic from bootcamp administrative functions which are stored in BootcampFactory contract.
2. We have 2 contracts: DepositHandler and BootcampFactory. DepositHandler contains main logic for managing bootcamps. BootcampFactory is our factory contract which will deploy bootcamp instances. Apart from that BootcampFactory also responsible for granting new roles for Managers and Admins, and withdrawing profit from the bootcamps.
3. Workflow:
 - User who deployed BootcampFactory automatically assigned as an Admin in this contract.
 - Admin is the main role and this user can grant or revoke roles like `MANAGER` or `ADMIN` role from users.
 - Manager is the 2nd role and users with this role are responsible for creation of the bootcamps. Once Manager create a new bootcamp - he/she automatically assigned to it as a bootcamp manager.
 - Manager can create a bootcamp with all needed parameters(bootcamp start time, bootcamp deadline, deposit amount, deposit token, withdraw duration...).
 - Once bootcamp is created, manager will select participants based on their applications(**at the moment this is handled manually**) and they will be allowed for depositing. Users can connect their wallet, and do a deposit before bootcamp start time.
 - When bootcamp will be finished, manager will select participants who passed it(**at the moment this is handled manually**) and allow them to withdraw their deposits. Withdraw can be done during a withdraw duration time period. Users who not passed a bootcamp will not be abl to withdraw their deposit.
4. How we handle edge cases with deposits?
 - If user has exception situation(health problems due to of which user can't attend classes, country problems or user just not agree with the final decision about his/her deposit refund), then he/she can contact manager and explain the situation. If manager is ok with the proofs from the user, then it is possible to return deposit back to user even if bootcamp is not yet finished, or already finsihed.
 - If an emergency situation appear(a bug was found or admin set up an incorrect bootcamp time duration...), then manager is able to do an emergency withdraw and all users will receive their deposits back.
5. How we handle issues, bugs, hacks?
 - At the moment we added a pausable mechanism, which can put on pause critical functionality of the DApp in case of strange behavior appear or bug was found.
 - Once issue will be investigated and resolved - all critical functinality will be uppaused.

## Frontend
Frontend implementation is here: https://github.com/0xKubko/encode-deposit-handler-fe

## Technology Stack & Tools
- [Solidity](https://docs.soliditylang.org/en/v0.8.28/) (Smart Contracts/Tests/Scripts)
- [Foundry](https://book.getfoundry.sh/) (Development Framework)

## Setting Up The Project
1. Clone/Download the Repository:
```shell
git https://github.com/ohMySol/encode-deposit-handler-sc.git
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