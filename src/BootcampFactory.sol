// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./DepositHandler.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {IBootcampFactoryErrors} from "./interfaces/ICustomErrors.sol";

/**
 * @title Bootcamp Factory contract.
 * @author @ohMySol, @nynko, @ok567
 * @notice Contract create new bootcamps.
 * @dev Contract for creation new instances of the `DepositHandler` contract with a Factory pattern. 
 * New instances are stored inside this factory contract and they can be quickly retrieved for the 
 * information and frontend usage.
 * 
 * Roles:
 *  1. ADMIN - main role which is set up automatically for a deployer address. This role should potentialy
 *  manage all underlying roles like MANAGER role, and grant a roles to a new users.
 *  2. MANAGER - 2nd role which is responsible for creating new bootcamp instances once new bootcamp is launched.
 */
contract BootcampFactory is AccessControl, IBootcampFactoryErrors {
    bytes32 public constant ADMIN = keccak256("ADMIN"); // Main Role
    bytes32 public constant MANAGER = keccak256("MANAGER"); // 2nd Roles
   
    uint256 public totalBootcampAmount;
    mapping (uint256 => Bootcamp) public bootcamps;

    event BootcampCreated (
        uint256 bootcampId,
        uint256 depositAmount,
        address depositToken,
        address bootcampAddress
    );
    struct Bootcamp {
        uint256 id;
        uint256 depositAmount;
        address depositToken;
        address bootcampAddress;
    }
    
    constructor() {
        _grantRole(ADMIN, msg.sender); // Grant the deployer the admin role
        _setRoleAdmin(MANAGER, ADMIN); // Set the `ADMIN` role as the administrator for the `MANAGER` role
    }

    /*//////////////////////////////////////////////////
                MANAGER FUNCTIONS
    /////////////////////////////////////////////////*/
    /**
     * @notice Managers are able to create a new bootcamp instance each time
     * they need to launch a new bootcamp.
     * @dev Create a new `DepositHandler` contract instance and set up a required 
     * bootcamp information in this instance: `_depositAmount` and `_depositToken`.
     * New bootcamp instance is stored in this factory contract in `bootcamp` mapping 
     * by unique id.
     * 
     * Emits a {BootcampCreated} event.
     * 
     * @param _depositAmount - bootcamp deposit amount.
     * @param _depositToken  - token address which is used for deposit. 
     */
    function createBootcamp(uint256 _depositAmount, address _depositToken) external onlyRole(MANAGER) {
        if (_depositToken == address(0)) {
            revert BootcampFactory__DepositTokenCanNotBeZeroAddress();
        }
        DepositHandler bootcamp = new DepositHandler(_depositAmount, _depositToken, msg.sender);

        totalBootcampAmount++;
        uint256 id = totalBootcampAmount; // store storage var-l locally
        bootcamps[id] = Bootcamp({
            id: id,
            depositAmount: _depositAmount,
            depositToken: _depositToken,
            bootcampAddress: address(bootcamp)
        });
        
        emit BootcampCreated(id, _depositAmount, _depositToken, address(bootcamp));
    }

    /*//////////////////////////////////////////////////
                ADMIN FUNCTIONS
    /////////////////////////////////////////////////*/
    /**
     * @notice Set a role to user.
     * @dev Set `MANAGER` or `ADMIN` role to `_account` address. Function restricred
     * to be called only by the `ADMIN` role.
     * 
     * @param _role - bytes32 respresentation of the role.
     * @param _account - address of the user that will have an new role.
     */
    function grantARole(bytes32 _role, address _account) external onlyRole(ADMIN) {
        if (_account == address(0)) {
            revert BootcampFactory__CanNotGrantRoleToZeroAddress();
        }
        if (_role == ADMIN || _role == MANAGER) {
            _grantRole(_role, _account);
        } else {
            revert BootcampFactory__GrantNonExistentRole();
        }
        
    }

    /**
     * @notice Remove role from user.
     * @dev Remove `MANAGER` or `ADMIN` role from `_manager` address. Function restricred
     * to be called only by the `ADMIN` role.
     *
     * @param _role - bytes32 respresentation of the role. 
     * @param _account - address of the user that has a `MANAGER` role.
     */
    function revokeARole(bytes32 _role, address _account) external onlyRole(ADMIN) {
        if (_account == address(0)) {
            revert BootcampFactory__CanNotRevokeRoleFromZeroAddress();
        }
        if (_role == ADMIN || _role == MANAGER) {
            _revokeRole(_role, _account);
        } else {
            revert BootcampFactory__GrantNonExistentRole();
        }
    }

    /*//////////////////////////////////////////////////
                VIEW FUNCTIONS
    /////////////////////////////////////////////////*/
    /**
     * @dev Returns a bootcamp information stored in `bootcamps` mapping.
     * @param _id - id of the bootcamp under which it is stored in `bootcamps` mapping.
     * 
     * @return `Bootcamp` structure is returned.
     */
    function getBootcamp(uint256 _id) external view returns (Bootcamp memory) {
        return bootcamps[_id];
    }
}