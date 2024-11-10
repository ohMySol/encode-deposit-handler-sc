// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {IDepositHandlerErrors} from "./interfaces/ICustomErrors.sol";
/*
1. Fuction to do a deposit for bootcamp. +
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
    uint256 public immutable bootcampDuration;
    uint256 public immutable bootcampStartTime;
    IERC20 public immutable depositToken;    
    mapping(address => depositInfo) public deposits;

    enum Status { // status of the bootcamp participant. 
        Deposit, // participant allowed for deposit
        InProgress, // participant passing a bootcamp
        Withdraw, // praticipant allowed for withdraw
        Pass // bootcamp passed
    }
    struct depositInfo {
        uint256 depositedAmount;
        Status status; //this is set by an admin from encode
    }
    event DepositDone(
        address depositor,
        uint256 depositAmount
    );
    event DepositWithdrawn(
        address depositor,
        uint256 withdrawAmount
    );

    /**
     * @dev Checks if user has a required status to do a deposit/withdraw. 
     */ 
    modifier isAllowed(Status _status) {
        Status status = deposits[msg.sender].status;
        if (status != _status) {
            revert DepositHandler__NotAllowedActionWithYourStatus();
        }
        _;
    }

    /**
     * @dev Checks if user has a required status to do a deposit/withdraw.
     * It is '<' instead of '<=', because I assume that encode team/manager need some time after
     * the final day of the bootcamp to sum up all participants results. Like a day after a bootcamp users
     * will be able to withdraw their deposits. 
     */
    
    modifier whenFinished {
        if (block.timestamp < bootcampStartTime + bootcampDuration) {
            revert DepositHandler__BootcampIsNotYetFinished();
        }
        _;
    }

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
     * the bootcamp. 
     * Function restrictions: 
     *  - Contract shouldn't be on Pause.
     *  - Can only be called when user has a status `Deposit`.
     * 
     * Emits a {DepositDone} event.
     * 
     * @param _amount - USDC amount.
     * @param _depositor - address of the bootcamp participant.
     */
    function deposit(uint256 _amount, address _depositor) external whenNotPaused isAllowed(Status.Deposit) { 
        uint256 allowance = depositToken.allowance(_depositor, address(this));
        if (_amount != depositAmount) {
            revert DepositHandler__IncorrectDepositedAmount(_amount);
        }
        if (allowance < _amount) {
            revert DepositHandler__ApprovedAmountLessThanDeposit(allowance);
        }

        deposits[_depositor].status = Status.InProgress; // set status to InProgress once user did a deposit, so that it means user is participating in bootcamp.
        deposits[_depositor].depositedAmount += _amount;
        depositToken.transferFrom(_depositor, address(this), _amount);
        emit DepositDone(_depositor, _amount);
    }

    /**
     * @dev Allow `_depositor` to withdraw USDC '_amount' from a bootcamp. 
     * Function restrictions: 
     *  - Contract shouldn't be on Pause.
     *  - Can only be called when user has a status `Withdraw`.
     * 
     * Emits a {DepositWithdrawn} event.
     * 
     * @param _amount - USDC amount.
     * @param _depositor - address of the bootcamp participant.
     */
    function withdraw(uint256 _amount, address _depositor) external whenNotPaused isAllowed(Status.Withdraw) {
        if (deposits[_depositor].depositedAmount != _amount) {
            revert DepositHandler__IncorrectAmountForWithdrawal(_amount);
        }
        
        deposits[_depositor].status = Status.Pass; // set status to Pass once user did a deposit withdrawal, so that it means user fully finished a bootcamp.
        deposits[_depositor].depositedAmount = 0;
        depositToken.transfer(_depositor, _amount);
        emit DepositWithdrawn(_depositor, _amount);
    }

    /*//////////////////////////////////////////////////
                ADMIN FUNCTIONS
    /////////////////////////////////////////////////*/
    /**
     * @notice Set contract on pause, and stop interraction with critical functions.
     * @dev Manager is able to put a contract on pause in case of vulnerability
     * or any other problem. Functions using `whenNotPaused()` modifier won't work.
     * Function restrictions:
     *  - Can only be called by `MANAGER` of this contract.
     */
    function pause() private onlyRole(MANAGER) {
        _pause();
    }

    /**
     * @notice Remove contract from pause, and allow interraction with critical functions.
     * @dev Manager is able to unpause a contract when vulnerability or
     * any other problem is resolved. Functions using `whenNotPaused()` modifier will work.
     * Function restrictions:
     *  - Can only be called by `MANAGER` of this contract.
     */
    function unpause() private onlyRole(MANAGER) {
        _unpause();
    }

    /**
     * @notice Allow a list of selected participants, who passed interview stage, 
     * to do a deposit to the bootcamp.
     * @dev Set `Deposit` status for all addresses in the `_participants` array.
     * Faster way to set status for a a list of participants instead of calling on eby one.
     * Function restrictions:
     *  - Can only be called by `MANAGER` of this contract.
     * 
     * @param _participants - array of participants addresses.
     */
    function allowDepositBatch(address[] calldata _participants) external onlyRole(MANAGER) {
        uint256 length = _participants.length;
        if (length == 0) {
            revert DepositHandler__ParticipantsArraySizeIsZero();
        }
        for (uint i = 0; i < length; i++) {
            _allowDeposit(_participants[i]);
        }
    }

    /**
     * @notice Allow a list of selected participants, who successfully finished a bootcamp
     * to withdraw their deposit from the bootcamp.
     * @dev Set `Withdraw` status for all addresses in the `_participants` array.
     * Faster way to set status for a a list of participants instead of calling on eby one.
     * Function restrictions:
     *  - Can only be called by `MANAGER` of this contract.
     *  - Can only be called when the bootcamp is finished.
     * 
     * @param _participants - array of participants addresses.
     */
    function allowWithdrawBatch(address[] calldata _participants) external whenFinished onlyRole(MANAGER) {
        uint256 length = _participants.length;
        if (length == 0) {
            revert DepositHandler__ParticipantsArraySizeIsZero();
        }
        for (uint i = 0; i < length; i++) {
            _allowWithdraw(_participants[i]);
        }
    }
    
    /**
     * @dev Set `Deposit` status for the `_participant` address, so that `_participant` will be able
     * to do a deposit.
     * Function restrictions:
     *  - Can only be called by `MANAGER` of this contract.
     * 
     * @param _participant - address of the user.
     */
    function _allowDeposit(address _participant) internal onlyRole(MANAGER) {
        if (_participant == address(0)) {
            revert DepositHandler__ParticipantAddressZero();
        }
        deposits[_participant].status = Status.Deposit;
    }

    /**
     * @dev Set `Withdraw` status for the `_participant` address, so that `_participant` will be able
     * to do a withdraw a deposit.
     * Function restrictions:
     *  - Can only be called by `MANAGER` of this contract.
     * 
     * @param _participant - address of the user.
     */
    function _allowWithdraw(address _participant) internal onlyRole(MANAGER) {
        if (_participant == address(0)) {
            revert DepositHandler__ParticipantAddressZero();
        }
        deposits[_participant].status = Status.Withdraw;
    }
}
