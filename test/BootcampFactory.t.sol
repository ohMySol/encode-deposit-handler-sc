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
                GRANTAROLE TESTS
    /////////////////////////////////////////////////*/
    function test_AdminSuccessfullyGrantManagerRoleToUser() public {
        vm.prank(admin);
        factory.grantARole(MANAGER, manager);
        
        assertTrue(factory.hasRole(MANAGER, manager));
    }

    function test_AdminSuccessfullyGrantAdminRoleToUser() public {
        vm.prank(admin);
        factory.grantARole(ADMIN, alice);
        
        assertTrue(factory.hasRole(ADMIN, alice));
    }

    function test_OnlyAdminCanGrantNewRoles() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            alice,
            ADMIN
        ));

        factory.grantARole(MANAGER, manager);
    }

    function test_AccountReceivingNewRoleCanNotBeAddressZero() public {
        vm.prank(admin);
        vm.expectRevert(
            IBootcampFactoryErrors.BootcampFactory__CanNotUpdateRoleForZeroAddress.selector
        );

        factory.grantARole(MANAGER, address(0));
    }

    function test_AdminCanNotGrantNonExistentRole() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(
            IBootcampFactoryErrors.BootcampFactory__UpdateNonExistentRole.selector, 
            INVALID_ROLE
        ));

        factory.grantARole(INVALID_ROLE, manager);
    }



    /*//////////////////////////////////////////////////
                REVOKEAROLE TESTS
    /////////////////////////////////////////////////*/
    function test_AdminSuccessfullyRevokeManagerRoleFromUser() public {
        vm.startPrank(admin);
        factory.grantARole(MANAGER, manager);
        factory.revokeARole(MANAGER, manager);
        
        assertFalse(factory.hasRole(MANAGER, manager));
    }
    
     function test_AdminSuccessfullyRevokeAdminRoleFromUser() public {
        vm.startPrank(admin);
        factory.grantARole(ADMIN, alice);
        factory.revokeARole(ADMIN, alice);

        assertFalse(factory.hasRole(ADMIN, alice));
    }

    function test_OnlyAdminCanRevokeTheRoles() public {
        vm.prank(admin);
        factory.grantARole(MANAGER, manager);
        
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            alice,
            ADMIN
        ));

        factory.revokeARole(MANAGER, manager);
    }

    function test_AccountLosingARoleCanNotBeAddressZero() public {
        vm.startPrank(admin);
        factory.grantARole(MANAGER, manager);

        vm.expectRevert(
            IBootcampFactoryErrors.BootcampFactory__CanNotUpdateRoleForZeroAddress.selector
        );

        factory.revokeARole(MANAGER, address(0));
    }
    
    function test_AdminCanNotRevokeNonExistentRole() public {
        vm.startPrank(admin);
        factory.grantARole(MANAGER, manager);

        vm.expectRevert(abi.encodeWithSelector(
            IBootcampFactoryErrors.BootcampFactory__UpdateNonExistentRole.selector, 
            INVALID_ROLE
        ));

        factory.revokeARole(INVALID_ROLE, manager);
    }


    
    /*//////////////////////////////////////////////////
                CREATEBOOTCAMP TESTS
    /////////////////////////////////////////////////*/
    function test_ManagerSuccessfullyCreateNewBootcamp() public {
        vm.prank(admin);
        factory.grantARole(MANAGER, manager);

        vm.prank(manager);
        factory.createBootcamp(
            networkConfig.depositAmount,
            networkConfig.depositToken,
            networkConfig.bootcampStartTime
        );
        uint256 bootcampId = factory.totalBootcampAmount();
        console.log(bootcampId);
        //BootcampFactory.Bootcamp memory bootcamp = factory.bootcamps(bootcampId);
    }
}
