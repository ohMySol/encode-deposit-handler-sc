// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// Custom errors for DepositHandler.sol
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
     * @dev Error indicates that manager tries to change a state of the contract for `address(0)`.
     */
    error DepositHandler__ParticipantAddressZero();

    /**
     * @dev Error indicates that manager calls a function with zero size array.
     */
    error DepositHandler__ParticipantsArraySizeIsZero();

    /**
     * @dev Error indicates that user tries to call a function without required status.
     */
    error DepositHandler__NotAllowedActionWithYourStatus();

    /**
     * @dev Error indicates that 
     */
    error DepositHandler__BootcampIsNotYetFinished();
}

/// Custom errors for BootcampFactory.sol
interface IBootcampFactoryErrors {
    /**
     * @dev Error indicates that user tries to grant a role to `addres(0)`.
     */
    error BootcampFactory__CanNotGrantRoleToZeroAddress();

    /**
     * @dev Error indicates that user tries to revoke a role from `addres(0)`.
     */
    error BootcampFactory__CanNotRevokeRoleFromZeroAddress();

    /**
     * @dev Error indicates that user tries to create a new bootcamp instance
     * with token address = `addres(0)`.
     */
    error BootcampFactory__DepositTokenCanNotBeZeroAddress();

     /**
     * @dev Error indicates that ADMIN tries to grant a role which doesn't exist.
     */
    error BootcampFactory__GrantNonExistentRole();
}