// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// Custom errors for DepositHandler.sol
interface IDepositHandlerErrors {
    
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
}