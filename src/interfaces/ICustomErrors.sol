// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// Custom errors for DepositHandler.sol
interface IDepositHandlerErrors {
    /**
     * @dev Error indicates that user tries to deposit an amount < `bootcampDeposit`.
     */
    error DepositHandler__IncorrectDepositedAmount(uint256 _actualAmount);

    /**
     * @dev Error indicates that user didn't allow contract to spent enough tokens.
     */
    error DepositHandler__ApprovedAmountLessThanDeposit(uint256 _approvedAmount);

    /**
     * @dev Error indicates that user request a wrong amount for withdrawal.
     */
    error DepositHandler__IncorrectAmountForWithdrawal(uint256 _withdrawAmount);

    /**
     * @dev Error indicates that someone set parameter `address(0)`.
     */
    error DepositHandler__UserAddressCanNotBeZero();

    /**
     * @dev Error indicates that manager calls a function with zero size array.
     */
    error DepositHandler__ParticipantsArraySizeIsZero();

    /**
     * @dev Error indicates that user tries to call a function without required status.
     */
    error DepositHandler__NotAllowedActionWithYourStatus();

    /**
     * @dev Error indicates that manager tries to allow users to withdraw when the bootcamp 
     * is not yet finished.
     */
    error DepositHandler__BootcampIsNotYetFinished();

    /**
     * @dev Error indicates that user trying to deposit funds for the bootcamp when
     *  depositing stage is already closed.
     */
    error DepositHandler__DepositingStageAlreadyClosed();

    /**
     * @dev Error indicates that user trying to withdraw funds from the bootcamp when
     *  withdraw stage is already closed.
     */
    error DepositHandler__WithdrawStageAlreadyClosed();

    /**
     * @dev Error indicates not a factory contract is trying to call this function.
     */
    error DepositHandler__CallerNotAFactoryContract();

    /**
     * @dev Error indicates that user is not a participant.
     */
    error DepositHandler__CallerNotParticipant();
}

// Custom errors for BootcampFactory.sol
interface IBootcampFactoryErrors {
    /**
     * @dev Error indicates that user tries to grant/revoke a role to/from `addres(0)`.
     */
    error BootcampFactory__CanNotUpdateRoleForZeroAddress();

    /**
     * @dev Error indicates that user tries to create a new bootcamp instance
     * with token address = `addres(0)`.
     */
    error BootcampFactory__DepositTokenCanNotBeZeroAddress();

     /**
     * @dev Error indicates that admin tries to grant/revoke a role which doesn't exist.
     */
    error BootcampFactory__UpdateNonExistentRole(bytes32 role);

    /**
     * @dev Error indicates that manager creating a bootcamp instance with a start time not in the future.
     */
    error BootcampFactory__InvalidBootcampStartTime();

    /**
     * @dev Error indicates that admin trying to withdraw money from non existent bootcamp.
     */
    error BootcampFactory__InvalidBootcampAddress();
}

// Custom errors for HelperConfig.sol 
interface IHelperConfigErrors {
    /**
     * @dev Error indicates that user trying to deploy a contract to unsupported network.
     */
    error HelperConfig_NotSupportedChain();
}