// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {DeployBootcampFactoryScript} from "../script/deploy/DeployBootcampFactory.s.sol";
import {IBootcampFactoryErrors} from "../src/interfaces/ICustomErrors.sol";
import {BootcampFactory} from "../src/BootcampFactory.sol"; 
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract BootcampFactoryTest is Test {
    bytes32 public constant ADMIN = keccak256("ADMIN"); // Main Role
    bytes32 public constant MANAGER = keccak256("MANAGER");
    bytes32 public constant INVALID_ROLE = bytes32("AVENGER");
    BootcampFactory public factory;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig networkConfig;
    
    address public admin; 
    address public manager;
    address public alice;

    event BootcampCreated (
        uint256 indexed bootcampId,
        address indexed bootcampAddress
    );

    // beforeEach hook
    modifier adminGrantManagerRole() {
        vm.startPrank(admin);
        factory.grantRole(MANAGER, manager);
        _;
    }

    function setUp() public {
        DeployBootcampFactoryScript deployer = new DeployBootcampFactoryScript();
        (factory, helperConfig) = deployer.deploy();
        networkConfig = helperConfig.getConfigByChainId(block.chainid);
        
        admin = vm.addr(networkConfig.admin);
        manager = vm.addr(networkConfig.manager);
        alice = makeAddr(("alice"));
    }



    /*//////////////////////////////////////////////////
                INITIALIZATION TESTS
    /////////////////////////////////////////////////*/
    function test_BootcampFactoryContractInitializedWithCorrectAdmin() public {
        assertTrue(factory.hasRole(ADMIN, admin));
        assertEq(factory.getRoleAdmin(MANAGER), ADMIN);
    }



    /*//////////////////////////////////////////////////
                GRANTROLE TESTS
    /////////////////////////////////////////////////*/
    function test_AdminSuccessfullyGrantManagerRoleToUser() public {
        vm.prank(admin);
        factory.grantRole(MANAGER, manager);
        
        assertTrue(factory.hasRole(MANAGER, manager));
    }

    function test_AdminSuccessfullyGrantAdminRoleToUser() public {
        vm.prank(admin);
        factory.grantRole(ADMIN, alice);
        
        assertTrue(factory.hasRole(ADMIN, alice));
    }

    function test_OnlyAdminCanGrantNewRoles() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            alice,
            ADMIN
        ));

        factory.grantRole(MANAGER, manager);
    }

    function test_AccountReceivingNewRoleCanNotBeAddressZero() public {
        vm.prank(admin);
        vm.expectRevert(
            IBootcampFactoryErrors.BootcampFactory__CanNotUpdateRoleForZeroAddress.selector
        );

        factory.grantRole(MANAGER, address(0));
    }

    function test_AdminCanNotGrantNonExistentRole() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(
            IBootcampFactoryErrors.BootcampFactory__UpdateNonExistentRole.selector, 
            INVALID_ROLE
        ));

        factory.grantRole(INVALID_ROLE, manager);
    }



    /*//////////////////////////////////////////////////
                REVOKEROLE TESTS
    /////////////////////////////////////////////////*/
    function test_AdminSuccessfullyRevokeManagerRoleFromUser() public adminGrantManagerRole {
        factory.revokeRole(MANAGER, manager);
        
        assertFalse(factory.hasRole(MANAGER, manager));
    }
    
     function test_AdminSuccessfullyRevokeAdminRoleFromUser() public adminGrantManagerRole {
        factory.revokeRole(ADMIN, alice);

        assertFalse(factory.hasRole(ADMIN, alice));
    }

    function test_OnlyAdminCanRevokeTheRoles() public adminGrantManagerRole {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            alice,
            ADMIN
        ));

        factory.revokeRole(MANAGER, manager);
    }

    function test_AccountLosingARoleCanNotBeAddressZero() public adminGrantManagerRole {
        vm.expectRevert(
            IBootcampFactoryErrors.BootcampFactory__CanNotUpdateRoleForZeroAddress.selector
        );

        factory.revokeRole(MANAGER, address(0));
    }
    
    function test_AdminCanNotRevokeNonExistentRole() public adminGrantManagerRole {
        vm.expectRevert(abi.encodeWithSelector(
            IBootcampFactoryErrors.BootcampFactory__UpdateNonExistentRole.selector, 
            INVALID_ROLE
        ));

        factory.revokeRole(INVALID_ROLE, manager);
    }


    
    /*//////////////////////////////////////////////////
                CREATEBOOTCAMP TESTS
    /////////////////////////////////////////////////*/
    function test_ManagerSuccessfullyCreateNewBootcamp() public adminGrantManagerRole {
        vm.startPrank(manager);
        factory.createBootcamp(
            networkConfig.depositAmount,
            networkConfig.depositToken,
            networkConfig.bootcampStartTime
        );
        uint256 bootcampId = factory.totalBootcampAmount();
        (
            uint256 id, 
            uint256 depositAmount, 
            address depositToken, 
            address bootcampAddress
        ) = factory.bootcamps(bootcampId);
        
        assertEq(id, 1);
        assertEq(depositAmount, networkConfig.depositAmount);
        assertEq(depositToken, networkConfig.depositToken);
        assertTrue(bootcampAddress != address(0));
    }

    function test_EventIsEmittedOnceBootcampIsCreated() public adminGrantManagerRole {
        vm.startPrank(manager);
        // recording data from events
        vm.recordLogs();
        factory.createBootcamp(
            networkConfig.depositAmount,
            networkConfig.depositToken,
            networkConfig.bootcampStartTime
        );
        Vm.Log[] memory logs = vm.getRecordedLogs(); // receive all the recorded logs
        uint256 bootcampId = uint256(logs[1].topics[1]);
        address bootcampAddress = address(uint160(uint256(logs[1].topics[2])));
        
        assertEq(bootcampId, 1);
        assertEq(bootcampAddress, 0xa16E02E87b7454126E5E10d957A927A7F5B5d2be);
    }

    function test_OnlyManagerCanCreateNewBootcamp() public adminGrantManagerRole {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            alice,
            MANAGER
        ));

        factory.createBootcamp(
            networkConfig.depositAmount,
            networkConfig.depositToken,
            networkConfig.bootcampStartTime
        );
    }

    function test_DepositTokenForBootcampCanNotBeAddressZero() public adminGrantManagerRole {
        vm.startPrank(manager);
        vm.expectRevert(
            IBootcampFactoryErrors.BootcampFactory__DepositTokenCanNotBeZeroAddress.selector
        );

        factory.createBootcamp(
            networkConfig.depositAmount,
            address(0),
            networkConfig.bootcampStartTime
        );
    }

    function test_BootcampStartDateCanNotBeInThePast() public adminGrantManagerRole {
        vm.startPrank(manager);
        vm.expectRevert(
            IBootcampFactoryErrors.BootcampFactory__InvalidBootcampStartTime.selector
        );

        uint256 oldTimestamp = block.timestamp; // Fixed timestamp in the past
        vm.warp(oldTimestamp + 1);
        factory.createBootcamp(
            networkConfig.depositAmount,
            networkConfig.depositToken,
            oldTimestamp
        );
    }
}
