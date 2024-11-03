// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDepositHandlerErrors} from "./interfaces/ICustomErrors.sol";

contract DepositHandler is IDepositHandlerErrors {
    address public admin;
    IERC20 public usdcToken;
    //mapping(address => uint256) public deposits; 
    //mapping(address => bool) public bootcampCompleted;
    mapping(address => depositInfo) public userDepositInfo;

    struct depositInfo{
        uint256 depositedAmount;
        bool bootcampCompleted; //this is set by an admin from encode (Centralised)
        bool yeild; //have not set this up yet
        bool multiSender; //have not set this up yet
    }

    constructor(address _usdcToken) {
        admin = msg.sender;
        usdcToken = IERC20(_usdcToken);
    }

    /*//////////////////////////////////////////////////
                USER FUNCTIONS
    /////////////////////////////////////////////////*/

    /**
     * @dev Allow user to deposit USDC '_amount' for a specific bootcamp. 
     * Deposited amount will be locked inside this contract till the end of
     * the bootcamp.
     * @param _amount - USDC amount,
     */
    function deposit(uint256 _amount) external { 
        require(_amount >= 249e18 && _amount <= 251e18, "Deposit must be 250USDC"); //maybe try and not hardcode, try and get the deposit value from the bootcampmanager +
        require(usdcToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        userDepositInfo[msg.sender].depositedAmount += _amount;
    }

    // Withdraw funds if bootcamp is completed
    function withdraw() external {
        depositInfo storage userInfo = userDepositInfo[msg.sender];

        require(userInfo.bootcampCompleted, "Bootcamp not successfully completed");
        uint256 depositAmount = userInfo.depositedAmount;
        require(depositAmount > 0, "No deposit to withdraw");

        // Reset deposit before transferring to prevent re-entrancy
        userInfo.depositedAmount = 0;

        require(usdcToken.transfer(msg.sender, depositAmount), "Transfer failed"); //change this to .call{value:....} as this the most approved way of transferring funds
    }

    /*//////////////////////////////////////////////////
                ADMIN FUNCTIONS
    /////////////////////////////////////////////////*/

    // Mark a user as having completed the bootcamp (only admin)
    function markBootcampComplete(address user) external {
        require(msg.sender == admin, "Only admin can mark completion"); //this could be done with a modifier instead to save gas?
        userDepositInfo[user].bootcampCompleted = true;
    }
}
