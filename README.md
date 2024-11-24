## DepositHandler
This is the 1st MVP DApp version. This code was thoroughly tested, but it can still have security issues or not be well optimized. All found issues will be solved in the next development iterations.
### Problem we are trying to solve:
The problem with scammers in the Encode community increases quite fast, and unfortunately more and more community members receive scam messages in Discord and Email. Our group realized that the current Encode depositing mechanism(sending a Polygon address via email to do a USDC deposit) is quite an unsafe way for users.\
So our team decided to create a DepositHandler DApp, which can significantly decrease the problem of scams. We decided to minimize users interaction with external resources like email, and allow them to do a deposit on-chain through our DApp. 

### Architecture
![img-alt](https://github.com/ohMySol/encode-deposit-handler-sc/blob/feature/Anton/DepositHandler.jpg?raw=true)

### How does this work?
Project consists of 2 parts: smart contracts and user friendly frontend. In this repo I'll describe only how the smart contracts part works.
1. We decided to follow a factory pattern and design our system in the way that we have a factory contract which is responsible for creating bootcamp contracts. This way allow us:
 - Simplify the process of deploying multiple instances of DepositHandler(bootcamp) contract.
 - We separate bootcamp management logic from bootcamp administrative functions which are stored in the BootcampFactory contract.
2. We have 2 contracts: DepositHandler and BootcampFactory. DepositHandler contains the main logic for managing bootcamps. BootcampFactory is our factory contract which will deploy bootcamp instances. Apart from that BootcampFactory is also responsible for granting new roles for Managers and Admins, and withdrawing profit from the bootcamps.
3. Workflow:
 - Users who deployed BootcampFactory automatically assigned as an Admin in this contract.
 - Admin is the main role and this user can grant or revoke roles like `MANAGER` or `ADMIN` role from users.
 - Manager is the 2nd role and users with this role are responsible for creation of the bootcamps. Once a Manager creates a new bootcamp - he/she automatically assigned to it as a bootcamp manager.
 - Manager can create a bootcamp with all needed parameters(bootcamp start time, bootcamp deadline, deposit amount, deposit token, withdrawal duration...).
 - Once bootcamp is created, the manager will select participants based on their applications(**at the moment this is handled manually**) and they will be allowed for depositing. Users can connect their wallet, and do a deposit before bootcamp start time.
 - When bootcamp is finished, the manager will select participants who passed it(**at the moment this is handled manually**) and allow them to withdraw their deposits. Withdraw can be done during a withdrawal duration time period. Users who have not passed a bootcamp will not be able to withdraw their deposit.
4. How do we handle edge cases with deposits?
 - If a user has an exceptional situation(health problems due to which the user can't attend classes, country problems or the user just does not agree with the final decision about his/her deposit refund), then he/she can contact the manager and explain the situation. If the manager is ok with the proof from the user, then it is possible to return the deposit back to the user even if bootcamp is not yet finished, or already finished.
 - If an emergency situation appears(a bug was found or the admin set up an incorrect bootcamp time duration...), then the manager is able to do an emergency withdrawal and all users will receive their deposits back.
5. How we handle issues, bugs, hacks?
 - At the moment we added a pausable mechanism, which can pause critical functionality of the DApp in case a strange behavior appears or a bug is found.
 - Once the issue will be investigated and resolved - all critical functionality will be unpaused.

## Potential future improvements:
1. **Abstraction + Cross Chain** 🌌. Support more types of deposits from more chains, providing more flexibility and possibilities for users liquidity.
2. **Monetisation** 💵. Introduce a fee switch to bring revenue in either in form of a portion of the yield or the deposit amount.
3. **Yield option**🤝. Underlying assets from deposits potentially can be staked(Aave, Morpho, Ethena…) and yield can be split with Encode.

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