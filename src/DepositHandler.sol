// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import {IDepositHandlerErrors} from "./interfaces/ICustomErrors.sol";

/**
 * @title Deposit Handler contract.
 * @author @ohMySol, @nynko, @ok567
 * @dev Contract for managing users deposits for bootcamps.
 * Implements both user part and admin part for deposit management.
 * Apart from that contract allow to manage admins and bootcamps.
 */
contract DepositHandler is IDepositHandlerErrors, Pausable {
    uint256 public immutable depositAmount;
    IERC20 public immutable depositToken;
    struct depositInfo {
        uint256 depositedAmount;
        bool bootcampCompleted; //this is set by an admin from encode (Centralised)
        bool yeild; //have not set this up yet
        bool multiSender; //have not set this up yet
    }
    
    //mapping(address => uint256) public deposits; 
    //mapping(address => bool) public bootcampCompleted;
    mapping(address => depositInfo) public userDepositInfo;
    
    constructor(uint256 _depositAmount, IERC20 _depositToken) {
        depositAmount = _depositAmount;
        depositToken = _depositToken;
    }

    /*//////////////////////////////////////////////////
                USER FUNCTIONS
    /////////////////////////////////////////////////*/
    /**
     * @dev Allow user to deposit USDC '_amount' for a specific bootcamp. 
     * Deposited amount will be locked inside this contract till the end of
     * the bootcamp.
     * @param _amount - USDC amount.
     */
    function deposit(uint256 _amount) external whenNotPaused { 
        require(_amount >= 249e18 && _amount <= 251e18, "Deposit must be 250USDC"); //maybe try and not hardcode, try and get the deposit value from the bootcampmanager +
        require(depositToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        userDepositInfo[msg.sender].depositedAmount += _amount;
    }

    /**
     * @dev Allow user to withdraw USDC '_amount' for a specific bootcamp. 
     * Deposited amount will be locked inside this contract till the end of
     * the bootcamp.
     */
    function withdraw() external whenNotPaused {
        depositInfo storage userInfo = userDepositInfo[msg.sender];

        require(userInfo.bootcampCompleted, "Bootcamp not successfully completed");
        uint256 amount = userInfo.depositedAmount;
        require(amount > 0, "No deposit to withdraw");

        // Reset deposit before transferring to prevent re-entrancy
        userInfo.depositedAmount = 0;

        require(depositToken.transfer(msg.sender, amount), "Transfer failed"); //change this to .call{value:....} as this the most approved way of transferring funds +
    }

    /*//////////////////////////////////////////////////
                ADMIN FUNCTIONS
    /////////////////////////////////////////////////*/
    // Mark a user as having completed the bootcamp (only admin)
    /* function markBootcampComplete(address user) external {
        // ! Require access control mechanism with the roles like in BootcampDepositFactory.sol.
        require(msg.sender == admin, "Only admin can mark completion"); //this could be done with a modifier instead to save gas?
        userDepositInfo[user].bootcampCompleted = true;
    } */

    /*//////////////////////////////////////////////////
                OWNER FUNCTIONS
    /////////////////////////////////////////////////*/
    /**
     * @dev Contract owner is able to put a contract on pause in case of vulnerability
     * or any other problem. Functions using 'whenNotPaused()' modifier won't work.
     */
    function pause() private { // ! requires access control
        _pause();
    }

    /**
     * @dev Contract owner is able to unpause a contract when vulnerability or
     * any other problem is resolved. Functions using 'whenNotPaused()' modifier will work.
     */
    function unpause() private { // ! requires access control
        _unpause();
    }
}
