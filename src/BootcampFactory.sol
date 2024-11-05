// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./DepositHandler.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BootcampFactory is AccessControl {
    event BootcampCreated (
        uint256 bootcampId,
        uint256 depositAmount,
        address bootcampAddress
    );

    bytes32 public constant ADMIN = keccak256("ADMIN"); // Main Role
    bytes32 public constant MANAGER = keccak256("MANAGER"); // 2nd Roles
    uint256 public totalBootcampAmount;

    mapping (uint256 => address) public bootcamps;

    constructor() {
        _grantRole(ADMIN, msg.sender); // Grant the deployer the admin role
        _setRoleAdmin(MANAGER, ADMIN); // Set the admin role as the administrator for the MANAGER role
    }

    function createBootcamp(uint256 _depositAmount, IERC20 _depositToken) external onlyRole(MANAGER) {
        DepositHandler bootcamp = new DepositHandler(_depositAmount, _depositToken);

        totalBootcampAmount++;
        bootcamps[totalBootcampAmount] = address(bootcamp);
        
        emit BootcampCreated(totalBootcampAmount, _depositAmount, address(bootcamp));
    }

    function grantManagerRole(address _manager) external onlyRole(ADMIN) {
        _grantRole(MANAGER, _manager);
    }

    function revokeManagerRole(address _manager) external onlyRole(ADMIN) {
        _revokeRole(MANAGER, _manager);
    }
}