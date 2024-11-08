// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {IDepositHandlerErrors} from "./interfaces/ICustomErrors.sol";
/*
1. Fuction to do a deposit for bootcamp.
2. Function to withdraw a deposit from bootcamp.
3. Pause function to pause a contract(only MANAGER).+
4. Unpause function to unpause a contract(only MANAGER).+
5. Function to get deposit information.
*/

/**
 * @title Deposit Handler contract.
 * @author @ohMySol, @nynko, @ok567
 * @dev Contract for managing users deposits for bootcamps.
 * Implements both user part and admin part for deposit management.
 * Apart from that contract allow to manage admins and bootcamps.
 */
contract DepositHandler is Pausable, AccessControl, IDepositHandlerErrors {
    bytes32 public constant MANAGER = keccak256("MANAGER");
    uint256 public immutable depositAmount;
    uint256 public immutable bootcampDuration; // store value in seconds.
    uint256 public immutable bootcampStartTime;
    IERC20 public immutable depositToken;
    //mapping(address => bool) public bootcampCompleted;
    mapping(address => depositInfo) public deposits;

    struct depositInfo {
        uint256 depositedAmount;
        bool bootcampCompleted; //this is set by an admin from encode (Centralised)
    }
    event DepositDone(
        address depositor,
        uint256 depositAmount
    );
    event DepositWithdrawn(
        address depositor,
        uint256 withdrawAmount
    );

    constructor(
        uint256 _depositAmount, 
        address _depositToken, 
        address _manager, 
        uint256 _bootcampDuration) 
    {
        depositAmount = _depositAmount;
        depositToken = IERC20(_depositToken);
        bootcampStartTime = block.timestamp;
        bootcampDuration = _bootcampDuration * 1 days;// duration value is converted to seconds.
        _grantRole(MANAGER, _manager);
    }

    /*//////////////////////////////////////////////////
                USER FUNCTIONS
    /////////////////////////////////////////////////*/
    /**
     * @notice Do deposit of USDC into this contract.
     * @dev Allow `_depositor` to deposit USDC '_amount' for a bootcamp. 
     * Deposited amount will be locked inside this contract till the end of
     * the bootcamp. Function restricted to be called only when contract is not on Pause.
     * 
     * Emits a {DepositDone} event.
     * 
     * @param _amount - USDC amount.
     * @param _depositor - address of the bootcamp participant.
     */
    function deposit(uint256 _amount, address _depositor) external whenNotPaused { 
        uint256 allowance = depositToken.allowance(_depositor, address(this));
        if (_amount != depositAmount) {
            revert DepositHandler__IncorrectDepositedAmount(_amount);
        }
        if (allowance < _amount) {
            revert DepositHandler__ApprovedAmountLessThanDeposit(allowance);
        }

        emit DepositDone(_depositor, _amount);
        deposits[_depositor].depositedAmount += _amount;
        depositToken.transferFrom(_depositor, address(this), _amount);
    }

    /**
     * @dev Allow `_depositor` to withdraw USDC '_amount' from a bootcamp. 
     * Function restricted to be called only when contract is not on Pause.
     * 
     * Emits a {DepositWithdrawn} event.
     * 
     * @param _amount - USDC amount.
     * @param _depositor - address of the bootcamp participant.
     */
    function withdraw(uint256 _amount, address _depositor) external whenNotPaused {
        if (getDeposit(_depositor) != _amount) {
            revert DepositHandler__IncorrectAmountForWithdrawal(_amount);
        }
        
        emit DepositWithdrawn(_depositor, _amount);
        deposits[_depositor].depositedAmount = 0;
        depositToken.transfer(_depositor, _amount);
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

    /**
     * @notice Set contract on pause, and stop interraction with critical functions.
     * @dev Manager is able to put a contract on pause in case of vulnerability
     * or any other problem. Functions using `whenNotPaused()` modifier won't work.
     * Function restricted to be called only by `MANAGER` of this contract.
     */
    function pause() private onlyRole(MANAGER) {
        _pause();
    }

    /**
     * @notice Remove contract from pause, and allow interraction with critical functions.
     * @dev Manager is able to unpause a contract when vulnerability or
     * any other problem is resolved. Functions using `whenNotPaused()` modifier will work.
     * Function restricted to be called only by `MANAGER` of this contract.
     */
    function unpause() private onlyRole(MANAGER) {
        _unpause();
    }

     /*//////////////////////////////////////////////////
                VIEW FUNCTIONS
    /////////////////////////////////////////////////*/
    /**
     * @dev Allow to query a deposited amount of tokens for `_depositor`.
     * 
     * @param _depositor - address of the person who did a deposit.
     * 
     * @return - `uint256` deposit value of the `_depositor`.
     */
    function getDeposit(address _depositor) public view returns (uint256) {
        return deposits[_depositor].depositedAmount;
    }
}
