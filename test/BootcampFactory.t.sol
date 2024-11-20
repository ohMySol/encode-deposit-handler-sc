// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {DeployBootcampFactoryScript} from "../script/deploy/DeployBootcampFactory.s.sol";
import {DepositTokenMock} from "../test/mocks/DepositTokenMock.sol";
import {BootcampFactory} from "../src/BootcampFactory.sol"; 
import {DepositHandler} from "../src/DepositHandler.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {IBootcampFactoryErrors} from "../src/interfaces/ICustomErrors.sol";

contract BootcampFactoryTest is Test {
    bytes32 public constant ADMIN = keccak256("ADMIN"); // Main Role
    bytes32 public constant MANAGER = keccak256("MANAGER");
    bytes32 public constant INVALID_ROLE = bytes32("AVENGER");
    BootcampFactory public factory;
    DepositTokenMock public tokenMock;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig networkConfig;
    
    address public admin; 
    address public manager;
    address public alice;
    address public bob;
    address public sam;

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
        tokenMock = DepositTokenMock(networkConfig.depositToken);

        admin = vm.addr(networkConfig.admin);
        manager = vm.addr(networkConfig.manager);
        alice = makeAddr("alice");
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
        address _bootcampAddress = factory.createBootcamp(
            networkConfig.depositAmount,
            networkConfig.depositToken,
            networkConfig.bootcampStart,
            networkConfig.bootcampDeadline,
            networkConfig.withdrawDuration,
            networkConfig.bootcampName
        );
        
        bool isBootcamp = factory.isBootcamp(_bootcampAddress);
        
        assertEq(isBootcamp, true);
    }

    function test_EventIsEmittedOnceBootcampIsCreated() public adminGrantManagerRole {
        vm.startPrank(manager);
        // recording data from events
        vm.recordLogs();
        address _bootcamAddress = factory.createBootcamp(
            networkConfig.depositAmount,
            networkConfig.depositToken,
            networkConfig.bootcampStart,
            networkConfig.bootcampDeadline,
            networkConfig.withdrawDuration,
            networkConfig.bootcampName
        );
        Vm.Log[] memory logs = vm.getRecordedLogs(); // receive all the recorded logs
        address bootcampAddress = address(uint160(uint256(logs[1].topics[1])));
        
        assertEq(bootcampAddress, _bootcamAddress);
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
            networkConfig.bootcampStart,
            networkConfig.bootcampDeadline,
            networkConfig.withdrawDuration,
            networkConfig.bootcampName
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
            networkConfig.bootcampStart,
            networkConfig.bootcampDeadline,
            networkConfig.withdrawDuration,
            networkConfig.bootcampName
        );
    }

    function test_BootcampCreationFailsIfStartDateInThePast() public adminGrantManagerRole {
        vm.startPrank(manager);
        vm.expectRevert(
            IBootcampFactoryErrors.BootcampFactory__InvalidBootcampStartOrDedlineTime.selector
        );

        uint256 oldTimestamp = block.timestamp; // Fixed timestamp in the past
        vm.warp(oldTimestamp + 1);
        factory.createBootcamp(
            networkConfig.depositAmount,
            networkConfig.depositToken,
            oldTimestamp,
            networkConfig.bootcampDeadline,
            networkConfig.withdrawDuration,
            networkConfig.bootcampName
        );
    }

    function test_BootcampCreationFailsIfStartDateIsActualTime() public adminGrantManagerRole {
        vm.startPrank(manager);
        vm.expectRevert(
            IBootcampFactoryErrors.BootcampFactory__InvalidBootcampStartOrDedlineTime.selector
        );

        factory.createBootcamp(
            networkConfig.depositAmount,
            networkConfig.depositToken,
            block.timestamp, // Start time == Actual time
            networkConfig.bootcampDeadline,
            networkConfig.withdrawDuration,
            networkConfig.bootcampName
        );
    }

    function test_BootcampCreationFailsIfDeadlineDateEqStartDate() public adminGrantManagerRole {
        vm.startPrank(manager);
        vm.expectRevert(
            IBootcampFactoryErrors.BootcampFactory__InvalidBootcampStartOrDedlineTime.selector
        );

        factory.createBootcamp(
            networkConfig.depositAmount,
            networkConfig.depositToken,
            networkConfig.bootcampStart,
            networkConfig.bootcampStart, // Deadline date == Start time
            networkConfig.withdrawDuration,
            networkConfig.bootcampName
        );
    }



    /*//////////////////////////////////////////////////
                WITHDRAWPROFIT TESTS
    /////////////////////////////////////////////////*/
    function test_AdminSuccessfullyWithdrawProfitFromBootcampContract() public adminGrantManagerRole {
        vm.startPrank(manager);
        // 1. Create bootcamp
        address _bootcampAddress = factory.createBootcamp(
            networkConfig.depositAmount,
            networkConfig.depositToken,
            networkConfig.bootcampStart,
            networkConfig.bootcampDeadline,
            networkConfig.withdrawDuration,
            networkConfig.bootcampName
        );
        DepositHandler bootcamp = DepositHandler(_bootcampAddress);
        console.log(_bootcampAddress);
        console.log("Is Bootcamp: ", factory.isBootcamp(_bootcampAddress));
        // 2. Fund alice address with USDC and do a deposit.
        vm.startPrank(alice);
        tokenMock.mint(alice, 100);
        tokenMock.approve(_bootcampAddress, 100000000);
        bootcamp.deposit(100000000, address(alice));

        // 3. Set participant as Donater, to withdraw later his deposit from the bootcamp.
        bootcamp.donate();

        // 4. Skip time to when withdraw stage already finsihed
        vm.warp(networkConfig.bootcampDeadline + networkConfig.withdrawDuration + 1);

        vm.startPrank(admin);
        // 5. Withdraw profit.
        factory.withdrawProfit(100000000, _bootcampAddress);

        assertEq(tokenMock.balanceOf(admin), 100000000);
        assertEq(tokenMock.balanceOf(_bootcampAddress), 0);
    }

    function test_EventIsEmittedAfterProfitWithdrawWithCorrectLogs() public adminGrantManagerRole {
        vm.startPrank(manager);
        // 1. Create bootcamp
        address _bootcampAddress = factory.createBootcamp(
            networkConfig.depositAmount,
            networkConfig.depositToken,
            networkConfig.bootcampStart,
            networkConfig.bootcampDeadline,
            networkConfig.withdrawDuration,
            networkConfig.bootcampName
        );
        DepositHandler bootcamp = DepositHandler(_bootcampAddress);
        
        // 2. Fund alice address with USDC and do a deposit.
        vm.startPrank(alice);
        tokenMock.mint(alice, 100);
        tokenMock.approve(_bootcampAddress, 100000000);
        bootcamp.deposit(100000000, address(alice));

        // 3. Set participant as Donater, to withdraw later his deposit from the bootcamp.
        bootcamp.donate();

        // 4. Skip time to when withdraw stage already finsihed
        vm.warp(networkConfig.bootcampDeadline + networkConfig.withdrawDuration + 1);

        vm.startPrank(admin);
        vm.recordLogs();
        // 5. Withdraw profit.
        factory.withdrawProfit(100000000, _bootcampAddress);
        Vm.Log[] memory logs = vm.getRecordedLogs(); // receive all the recorded logs
        // 6. Parse logs.    
        address adminAddress = address(uint160(uint256(logs[1].topics[1])));
        (uint256 withdrawnAmount, uint256 remainingBalance) = abi.decode(logs[1].data, (uint256, uint256));
                
        assertEq(adminAddress, admin);
        assertEq(withdrawnAmount, 100000000);
        assertEq(remainingBalance, 0);            
    }

    function test_WithdrawProfitRevertsIfCallerIsNotAdmin() public {
        vm.startPrank(manager);
        vm.expectRevert(abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            manager,
            ADMIN
        ));
        
        factory.withdrawProfit(100000000, makeAddr("random address"));
    }

    function test_WithdrawProfitRevertsIfBootcampParameterIsZero() public {
        vm.startPrank(admin);
        vm.expectRevert(
            IBootcampFactoryErrors.BootcampFactory__InvalidBootcampAddress.selector
        );
        
        factory.withdrawProfit(100000000, address(0));
    }

    function test_WithdrawProfitRevertsIfBootcampParameterIsNotAnActualBootcamp() public {
        vm.startPrank(admin);
        vm.expectRevert(
            IBootcampFactoryErrors.BootcampFactory__InvalidBootcampAddress.selector
        );
        
        factory.withdrawProfit(100000000, makeAddr("random address"));
    }
}

