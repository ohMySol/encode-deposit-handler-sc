// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {IDepositHandlerErrors} from "./interfaces/ICustomErrors.sol";

/**
 * @title Deposit Handler contract.
 * @author @ohMySol, @nynko, @ok567, @kubko
 * @dev Contract for managing users deposits for bootcamps.
 * Implements both user part and manager part for deposit management.
 */
contract DepositHandler is Pausable, AccessControl, IDepositHandlerErrors {
    bytes32 public constant MANAGER = keccak256("MANAGER");
    uint256 public immutable depositAmount;
    uint256 public immutable bootcampStartTime;
    uint256 public immutable bootcampDeadline;
    uint256 public immutable withdrawDuration;
    IERC20 public immutable depositToken;
    address public immutable factory;
    string public bootcampName;
    uint256 public bootcampFinishTime;
    address[] public emergencyWithdrawParticipants;
    mapping(address => depositInfo) public deposits;
    mapping(address => bool) public isParticipant;

    enum Status { // status of the bootcamp participant. 
        InProgress, // participant passing a bootcamp.
        Withdraw, // praticipant allowed for withdraw.
        Passed, // bootcamp was passed successfully, and deposit will be returned.
        NotPassed, // bootcamp wasn't passed successfully, so that deposit won't be returned.
        Emergency
    }
    struct depositInfo {
        uint256 depositedAmount;
        bool depositDonation; // user can donate his deposit to Encode(true - donete/ false - want take it back)
        Status status;
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
     * @dev Checks if user has a required status to do a withdraw. 
     */ 
    modifier isAllowed(Status _status) {
        Status status = deposits[msg.sender].status;
        if (status != _status) {
            revert DepositHandler__NotAllowedActionWithYourStatus();
        }
        _;
    }

    constructor(
        uint256 _depositAmount, 
        address _depositToken, 
        address _manager, 
        uint256 _bootcampStartTime,
        uint256 _bootcampDeadline,
        uint256 _withdrawDuration,
        address _factory,
        string memory _bootcampName
    ) 
    {
        depositAmount = _depositAmount;
        depositToken = IERC20(_depositToken);
        bootcampStartTime = _bootcampStartTime;
        bootcampDeadline = _bootcampDeadline;
        withdrawDuration = _withdrawDuration;
        factory = _factory;
        bootcampName = _bootcampName;
        _grantRole(MANAGER, _manager);
    }

    /**
     * @notice Admin is able to withdraw tokens after bootcamp completion.
     * @dev Admin from `BootcampFactory` contract is able to withdraw tokens from the bootcamp
     * contract.
     * Function restrictions:
     *  - Can only be called by `BootcampFactory` contract.
     *  - Bootcamp should be finished and withdraw stage already closed.
     *  - `_admin` can not be address(0)
     *  - `_amount` should be <= balance of this contract.
     *  - contract shouldn't be on Pause.
     * 
     * @param _admin - admin who will receive a tokens.
     * @param _amount - amount of tokens.
     * 
     * @return - `remainingBalance` of this bootcamp contract.
     */
    function withdrawAdmin(address _admin, uint256 _amount) external whenNotPaused returns(uint256) {
        _isWithdrawStageFinished();
        if (msg.sender != factory) {
            revert DepositHandler__CallerNotAFactoryContract();
        }
        uint256 _balance = depositToken.balanceOf(address(this));
        uint256 remainingBalance = _balance - _amount;
        if (_amount > _balance) {
            revert DepositHandler__IncorrectAmountForWithdrawal(_amount);
        } 
        
        SafeERC20.safeTransfer(depositToken, _admin, _amount);

        return remainingBalance;
    }

    /*//////////////////////////////////////////////////
                USER FUNCTIONS
    /////////////////////////////////////////////////*/
    /**
     * @dev Set `depositDonation` flag to true in `depositInfo` for specific user.
     * Function restrictions:
     *  - Can only be called by a participant of the bootcamp.
     */
    function donate() external whenNotPaused {
        if(!isParticipant[msg.sender]) {
            revert DepositHandler__CallerNotParticipant();
        }

        deposits[msg.sender].depositDonation = true;
    }

    /**
     * @notice Do deposit of USDC into this contract.
     * @dev Allow `_depositor` to deposit USDC '_amount' for a bootcamp. Deposited amount will be 
     * locked inside this contract till the end ofthe bootcamp, except emergency situation or extra situation, 
     * when deposit can be withdrawn before bootcamp finish. 
     * Function restrictions: 
     *  - Contract shouldn't be on Pause.
     *  - Can only be called before the `bootcampStartTime`.
     *  - `_amount` value should be the same as required in `depositAmount`.
     *  - Caller should allow this contract to spend his USDC, before calling this function.
     * 
     * Emits a {DepositDone} event.
     * 
     * @param _amount - USDC amount.
     * @param _depositor - address of the bootcamp participant.
     */
    function deposit(uint256 _amount, address _depositor) external whenNotPaused {
        _notAddressZero(_depositor);
        uint256 allowance = depositToken.allowance(_depositor, address(this));
        if (block.timestamp > bootcampStartTime) { // checking that user can do a deposit only during depositing stage(before bootcamp starts)
            revert  DepositHandler__DepositingStageAlreadyClosed();
        }
        if (_amount != depositAmount) {
            revert DepositHandler__IncorrectDepositedAmount(_amount);
        }
        if (allowance < _amount) {
            revert DepositHandler__ApprovedAmountLessThanDeposit(allowance);
        }
        
        deposits[_depositor].depositedAmount += _amount;
        deposits[_depositor].status = Status.InProgress; // set status to InProgress once user did a deposit, so that it means user is participating in bootcamp.
        isParticipant[_depositor] = true;
        emergencyWithdrawParticipants.push(_depositor);
        SafeERC20.safeTransferFrom(depositToken, _depositor, address(this), _amount);
        
        emit DepositDone(_depositor, _amount);
    }

    /**
     * @notice Participant can withdraw his USDC deposit through this function.
     * @dev Allow `_depositor` to withdraw USDC '_amount' from a bootcamp. 
     * Function restrictions: 
     *  - Contract shouldn't be on Pause.
     *  - Can only be called when user has a status `Withdraw`.
     *  - Can only be called when `bootcampWithdrawTime` is not elapsed.
     * 
     * @param _amount - USDC amount.
     * @param _depositor - address of the participant.
     */
    function withdraw(uint256 _amount, address _depositor) external isAllowed(Status.Withdraw) {
        _isWithdrawStageFinished();
        _withdraw(_amount, _depositor, Status.Passed);
    }

    /**
     * @notice Manager si able to withdraw users deposits back to them if some emergency situation appear.
     * Everyone who participated in the bootcamp will receive their deposit back in case of emergency.
     * Example of emergency situation:
     *  1. Manager set up incorrect(too long duration).
     *  2. Smth happens on Encode side.
     *  3. Stange activity mentioned in the contract.
     * @dev Allow to withdraw users funds if an emergency situation appear. Function once called, will send
     * all users deposits back to them.   
     * Function restrictions:
     *  - Can only be called when contract is not on Pause.
     *  - Can only be called when `allowEmergencyWithdraw` is true.
     *  - Can only be called by `MANAGER`.
     *  - Contract shouldn't be on Pause.
     * Function omits the next checks:
     *  - No check whether the user has a `Withdraw` status.
     */
    function emergencyWithdraw() external onlyRole(MANAGER) {
        address[] memory participants = emergencyWithdrawParticipants;
        uint256 length = participants.length;
        uint256 amount = depositAmount;

        for (uint256 i = 0; i < length; i++) {
            _withdraw(amount, participants[i], Status.Emergency);   
        }
    }

    /**
     * @dev Withdraw `_depositor` USDC '_amount' from a bootcamp back to `_depositor`,
     * and set an appropriate `_status` to `_depositor`. 
     * Function restrictions: 
     *  - Contract shouldn't be on Pause.
     *  - `_amount` value should be the same as required in `depositAmount`.
     *  - `depositor` address can't be address(0).
     * 
     * Emits a {DepositWithdrawn} event.
     * 
     * @param _amount - USDC amount.
     * @param _depositor - address of the bootcamp participant. 
     * @param _status - status of the participant after withdrawal.
     */
    function _withdraw(uint256 _amount, address _depositor, Status _status) internal whenNotPaused {
        _notAddressZero(_depositor);
        _checkWithdrawAmount(_amount, _depositor);
        
        deposits[_depositor].status = _status; // based on the situation, manager will assign an appropriate status.
        deposits[_depositor].depositedAmount = 0;
        isParticipant[_depositor] = false; // once withdraw user no longer a participant
        SafeERC20.safeTransfer(depositToken, _depositor, _amount);
        
        emit DepositWithdrawn(_depositor, _amount);
    }

    /**
     * @dev Verifies that `_user`  address is not a zero address.
     * 
     * @param _user - address of the user.
     */
    function _notAddressZero(address _user) internal pure {
        if (_user == address(0)) {
            revert DepositHandler__UserAddressCanNotBeZero();
        }
    }

    /**
     * @dev Verifies that `_amount` requested for a withdraw equals original deposited USDC amount.
     * 
     * @param _amount - amount of USDC to withdaw.
     * @param _participant - address of the participant.
     */
    function _checkWithdrawAmount(uint256 _amount, address _participant) internal view {
        if (deposits[_participant].depositedAmount != _amount) {
            revert DepositHandler__IncorrectAmountForWithdrawal(_amount);
        }
    }

    /**
     * @dev Verifies whether a withdraw stage is already finished, or not.
     */
    function _isWithdrawStageFinished() internal view {
        if (bootcampDeadline + withdrawDuration > block.timestamp) {
            revert DepositHandler__WithdrawStageAlreadyClosed();
        }
    }

    /*//////////////////////////////////////////////////
                MANAGER FUNCTIONS
    /////////////////////////////////////////////////*/
    /**
     * @notice Set a specific status for a batch of participants.
     * Examples:
     * 1. If manager want to allow participants to withdraw:
     *  - Manager will call this function and assign a `Withdraw` status for all `_participants`.
     * 2. If manager want to set participants who not passed a bootcam:
     *  - Manager will call this function and assign a `NotPassed` status for all `_participants`.
     * @dev Set `_status` for all addresses in the `_participants` array.
     * Faster way to set status for a a list of participants instead of calling one by one.
     * Function restrictions:
     *  - Can only be called by `MANAGER` of this contract.
     *  - `_participants` array can not be 0 length.
     * 
     * @param _status - status to be set.
     * @param _participants - array of participants addresses.
     */
    function updateStatusBatch(address[] calldata _participants, Status _status) external onlyRole(MANAGER) {
        uint256 length = _participants.length;
        if (length == 0) {
            revert DepositHandler__ParticipantsArraySizeIsZero();
        }
        for (uint i = 0; i < length; i++) {
            if (_status == Status.Withdraw && deposits[_participants[i]].depositDonation) { // if user is a donater, then we won't assign him a Withdraw status and he won't be able to withdraw.
                continue;
            }
            _setStatus(_participants[i], _status);
        }
    }

    /**
     * @notice Set `participant` status to track his progress during the bootcamp.
     * @dev Set status from `Status` enum for specific bootcamp `participant`.
     * Function restrictions:
     *  - Can only be called by `MANAGER` of this contract.
     *  - `_participant` address can't be address(0).
     * 
     * @param _participant - address of the bootcamp participant.
     * @param _status - status of the participant progress.
     */
    function _setStatus(address _participant, Status _status) internal onlyRole(MANAGER) {
        _notAddressZero(_participant);
        deposits[_participant].status = _status;
    }

    /**
     * @notice If user has an extra situation:
     *  - accidentally deposited to this bootcamp.
     *  - health problem.
     *  - disagree with the graduation and deposit refunding.
     *  - any other extra reason why user can't attend a bootcamp or why user skipped a bootcamp while deposited to it.
     * then it is possible to talk to manager and if manager approve the situation, then an extra withdraw can be done 
     * with a relevant status change for a user. 
     * @dev Manager can do an extra withdrawal for `_participant` based on the provided circumstances.
     * Function omits the next checks:
     *  - No check whether the user has a `Withdraw` status.
     *  - No check for the bootcamp finality.
     * Function restrictions:
     *  - Can only be called by `MANAGER` of this contract.
     *  - Contract shouldn't be on Pause.
     *
     * @param _amount - deposited amoount for the bootcamp.
     * @param _participant - address of the participant requesting extra withdraw.
     * @param _status  - `Status` which admin should set for this participant, based on the situation.
     */
    function exceptionalWithdraw(uint256 _amount, address _participant, Status _status) external onlyRole(MANAGER) {
        _withdraw(_amount, _participant, _status);// based on the situation, manager will assign an appropriate status.
    }

    /**
     * @notice Set contract on pause, and stop interraction with critical functions.
     * @dev Manager is able to put a contract on pause in case of vulnerability
     * or any other problem. Functions using `whenNotPaused()` modifier won't work.
     * Function restrictions:
     *  - Can only be called by `MANAGER` of this contract.
     */
    function pause() public onlyRole(MANAGER) {
        _pause();
    }

    /**
     * @notice Remove contract from pause, and allow interraction with critical functions.
     * @dev Manager is able to unpause a contract when vulnerability or
     * any other problem is resolved. Functions using `whenNotPaused()` modifier will work.
     * Function restrictions:
     *  - Can only be called by `MANAGER` of this contract.
     */
    function unpause() public onlyRole(MANAGER) {
        _unpause();
    }
}
