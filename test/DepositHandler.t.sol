// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {DeployDepositHandlerScript} from "../script/deploy/DeployDepositHandler.s.sol";
import {DepositHandler} from "../src/DepositHandler.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DepositTokenMock} from "../test/mocks/DepositTokenMock.sol";
import {IDepositHandlerErrors} from "../src/interfaces/ICustomErrors.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract DepositHandlerTest is Test {
    bytes32 public constant MANAGER = keccak256("MANAGER");
    bytes32 public constant INVALID_ROLE = bytes32("AVENGER");
    DepositHandler public bootcamp;
    DepositTokenMock public depositToken;
    HelperConfig.NetworkConfig networkConfig;
    
    address public manager;
    address public alice;
    address public bob;
    address public charlie;

    event DepositDone(
        address depositor,
        uint256 depositAmount
    );
    event DepositWithdrawn(
        address depositor,
        uint256 withdrawAmount
    );

    function setUp() public {
        DeployDepositHandlerScript deployer = new DeployDepositHandlerScript();
        (bootcamp, networkConfig) = deployer.deploy(); // receive instances from deploy script based on the network

        // Deploy the mock DepositToken if needed (this happens in HelperConfig for local chain)
        depositToken = DepositTokenMock(networkConfig.depositToken); // Get the mock token address from the config

        manager = vm.addr(networkConfig.manager); // manager who depployed a bootcamp contract
        alice = makeAddr(("alice")); // some other user without MANAGER role.
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        depositToken.mint(alice, 100);
        depositToken.mint(bob, 100);
        depositToken.mint(charlie, 100);
    }


    /*//////////////////////////////////////////////////
                INITIALIZATION TESTS
    /////////////////////////////////////////////////*/
    function test_DepositHandlerContractInitializedWithCorrectValues() view public{
        assertTrue(bootcamp.hasRole(MANAGER, manager));
        assertEq(bootcamp.depositAmount(), networkConfig.depositAmount);
        assertEq(address(bootcamp.depositToken()), networkConfig.depositToken);
        assertEq(bootcamp.bootcampStart(), networkConfig.bootcampStart);
        assertEq(bootcamp.bootcampName(), networkConfig.bootcampName);
        assertEq(bootcamp.bootcampDeadline(), networkConfig.bootcampDeadline);
        assertEq(bootcamp.withdrawDuration(), networkConfig.withdrawDuration);
        assertEq(bootcamp.factory(), networkConfig.factory);
    }

    /*//////////////////////////////////////////////////
                DEPOSIT FUNCTION TESTS
    /////////////////////////////////////////////////*/

    function test_DepositFunction_Success() public {
        uint256 aliceInitialBalance = depositToken.balanceOf(alice);
        assertTrue(aliceInitialBalance >= networkConfig.depositAmount, "Alice does not have enough tokens for deposit"); //check alice has enough
        assertTrue(alice != address(0), "Deposit recipient cannot be zero address"); //checks that it isnt a zero address
    
        vm.prank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount); //approve the bootcamp contract to spend their allowance granted by alice

        uint256 approvedAmount = depositToken.allowance(alice, address(bootcamp));
        assertEq(approvedAmount, networkConfig.depositAmount, "Approval amount mismatch"); //ensure approved amount is equal to depositamount

        vm.prank(alice);
        emit DepositDone(alice, networkConfig.depositAmount);
        bootcamp.deposit(); //deposit amount to bootcamp

        (uint256 depositedAmount, , DepositHandler.Status status) = bootcamp.deposits(alice);
        assertEq(depositedAmount, networkConfig.depositAmount, "Deposit amount mismatch"); //ensure that the amount deposited is equal to the despoistAmount of the bootcamp
        assertEq(uint256(status), uint256(DepositHandler.Status.InProgress), "Deposit status mismatch"); //check that alice has the status of inProgress
    }

    function test_DepositFunction_Revert_When_User_Do_Double_Deposit() public {
        uint256 aliceInitialBalance = depositToken.balanceOf(alice);
        assertTrue(aliceInitialBalance >= networkConfig.depositAmount, "Alice does not have enough tokens for deposit"); //check alice has enough
        assertTrue(alice != address(0), "Deposit recipient cannot be zero address"); //checks that it isnt a zero address
    
        vm.startPrank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount); //approve the bootcamp contract to spend their allowance granted by alice

        uint256 approvedAmount = depositToken.allowance(alice, address(bootcamp));
        assertEq(approvedAmount, networkConfig.depositAmount, "Approval amount mismatch"); //ensure approved amount is equal to depositamount

        emit DepositDone(alice, networkConfig.depositAmount);
        bootcamp.deposit(); //deposit amount to bootcamp

        (uint256 depositedAmount, , DepositHandler.Status status) = bootcamp.deposits(alice);
        assertEq(depositedAmount, networkConfig.depositAmount, "Deposit amount mismatch"); //ensure that the amount deposited is equal to the despoistAmount of the bootcamp
        assertEq(uint256(status), uint256(DepositHandler.Status.InProgress), "Deposit status mismatch"); //check that alice has the status of inProgress

        vm.expectRevert(IDepositHandlerErrors.DepositHandler__UserAlreadyDeposited.selector);
        bootcamp.deposit();
    }

    function test_Deposit_After_Bootcamp_Start() public {
        vm.warp(networkConfig.bootcampStart + 1); // warp the blockchain time to just after the bootcamp starts

        uint256 aliceInitialBalance = depositToken.balanceOf(alice);
        assertTrue(aliceInitialBalance >= networkConfig.depositAmount, "Alice does not have enough tokens for deposit");

        vm.prank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);

        // Attempt to deposit before bootcamp starts, should revert
        vm.prank(alice);
        vm.expectRevert(IDepositHandlerErrors.DepositHandler__DepositingStageAlreadyClosed.selector);
        bootcamp.deposit();
    }

    function test_Deposit_Fails_When_Contract_Paused() public {
        // aice tries to deposit, and the contract is not paused initially
        uint256 aliceInitialBalance = depositToken.balanceOf(alice);
        assertTrue(aliceInitialBalance >= networkConfig.depositAmount, "Alice does not have enough tokens for deposit");

        vm.prank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);

        // manager pauses the contract
        vm.prank(manager);
        bootcamp.pause();

        // alice tries to deposit while the contract is paused, expecting a revert
        vm.prank(alice);
        vm.expectRevert(Pausable.EnforcedPause.selector); // Check for the correct revert reason when contract is paused
        bootcamp.deposit();

        // manager unpauses the contract
        vm.prank(manager);
        bootcamp.unpause();

        // alice tries to deposit again when the contract is unpaused, expecting success
        vm.prank(alice);
        bootcamp.deposit();

        // verify that the deposit was successful
        (uint256 depositedAmount, ,DepositHandler.Status status) = bootcamp.deposits(alice);
        assertEq(depositedAmount, networkConfig.depositAmount, "Deposit amount mismatch");
        assertEq(uint256(status), uint256(DepositHandler.Status.InProgress), "Deposit status mismatch");
    }

     /*//////////////////////////////////////////////////
                WITHDRAW FUNCTION TESTS
    /////////////////////////////////////////////////*/

    function test_Withdrawal_Success_AfterGraduating() public { 
        vm.startPrank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();

        //Manager assigns Alice the status 'withdraw' using the updatestatusbatch function
        vm.startPrank(manager);

        address[] memory emergencyWithdrawParticipants = new address[](1);
        emergencyWithdrawParticipants[0] = address(alice);
        bootcamp.updateStatusBatch(emergencyWithdrawParticipants, DepositHandler.Status.Withdraw);
        

        //Alice withdraws her deposit
        (uint256 aliceDepositBeforeWithdrawal, ,)  = bootcamp.deposits(alice);
        uint256 aliceBalanceBeforeWithdrawal = depositToken.balanceOf(alice);
        
        vm.startPrank(alice);
        bootcamp.withdraw(); // Alice withdraws the deposit
        
        (uint256 aliceDepositAfterWithdrawal, , DepositHandler.Status status) = bootcamp.deposits(alice);
        uint256 aliceBalanceAfterWithdrawal = depositToken.balanceOf(alice);

        
        assertEq(aliceDepositBeforeWithdrawal, networkConfig.depositAmount); //verifies that the alice has deposited and is withdrawing the correct amount
        assertEq(aliceDepositAfterWithdrawal, 0); // Deposit should be withdrawn
        assertEq(aliceBalanceAfterWithdrawal, aliceBalanceBeforeWithdrawal + networkConfig.depositAmount); //verfies that she has withdraw and recieved the correct amount
        assertEq(uint256(status), uint256(DepositHandler.Status.Passed), "Deposit status mismatch"); //test that alice has now passed!!
    
        emit DepositWithdrawn(alice, networkConfig.depositAmount);
    } 

    function test_Withdraw_Revert_WhenAddressIsZero() public {
        // manager tries to withdraw to address(0)
        address[] memory emergencyWithdrawParticipants = new address[](1);
        emergencyWithdrawParticipants[0] = address(0);

        vm.prank(manager);
        vm.expectRevert(IDepositHandlerErrors.DepositHandler__UserAddressCanNotBeZero.selector);
        bootcamp.updateStatusBatch(emergencyWithdrawParticipants, DepositHandler.Status.Withdraw);
    }


    function test_Withdrawal_Failure_NotGraduated() public {
        vm.startPrank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();

        //alice tries to withdraw without having the 'Withdraw' status
        vm.expectRevert(IDepositHandlerErrors.DepositHandler__NotAllowedActionWithYourStatus.selector);

        vm.startPrank(alice);
        bootcamp.withdraw();
    }

    function test_Withdrawal_Fails_When_Not_Participant_Withdrawing() public {
        vm.startPrank(charlie);

        //charlie tries to withdraw without not been a participant
        vm.expectRevert(IDepositHandlerErrors.DepositHandler__CallerNotParticipant.selector);

        bootcamp.withdraw();
    }

    function test_EmergencyWithdraw_Success() public {
        //Alice, Bob, and Charlie deposit the required amount. Which in turn adds them to emergencyWithdrawParticipants
        vm.startPrank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();
        vm.stopPrank();

        vm.startPrank(bob);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();
        vm.stopPrank();

        vm.startPrank(charlie);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();
        vm.stopPrank();

        
        // manager calls emergencyWithdraw
        uint256 aliceInitialBalance = depositToken.balanceOf(alice);
        uint256 bobInitialBalance = depositToken.balanceOf(bob);
        uint256 charlieInitialBalance = depositToken.balanceOf(charlie);

        vm.prank(manager);
        bootcamp.emergencyWithdraw();

        // verify that all participants got their deposits back and their status was updated
        (uint256 aliceDepositAfter, ,DepositHandler.Status aliceStatusAfter) = bootcamp.deposits(alice);
        (uint256 bobDepositAfter, ,DepositHandler.Status bobStatusAfter) = bootcamp.deposits(bob);
        (uint256 charlieDepositAfter, ,DepositHandler.Status charlieStatusAfter) = bootcamp.deposits(charlie);

        assertEq(aliceDepositAfter, 0, "Alice's deposit should be 0 after withdrawal");
        assertEq(bobDepositAfter, 0, "Bob's deposit should be 0 after withdrawal");
        assertEq(charlieDepositAfter, 0, "Charlie's deposit should be 0 after withdrawal");

        assertEq(uint256(aliceStatusAfter), uint256(DepositHandler.Status.Emergency), "Alice's status should be Passed");
        assertEq(uint256(bobStatusAfter), uint256(DepositHandler.Status.Emergency), "Bob's status should be Passed");
        assertEq(uint256(charlieStatusAfter), uint256(DepositHandler.Status.Emergency), "Charlie's status should be Passed");

        // verify balances were refunded
        assertEq(depositToken.balanceOf(alice), aliceInitialBalance + networkConfig.depositAmount, "Alice should have her deposit refunded");
        assertEq(depositToken.balanceOf(bob), bobInitialBalance + networkConfig.depositAmount, "Bob should have his deposit refunded");
        assertEq(depositToken.balanceOf(charlie), charlieInitialBalance + networkConfig.depositAmount, "Charlie should have his deposit refunded");

    }

    function test_Withdraw_Reverts_When_Paused() public {
        // Set up initial deposit for alice
        vm.startPrank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();
        vm.stopPrank();

        // manager updates status to withdraw, and pauses the contract
        vm.startPrank(manager);

        address[] memory emergencyWithdrawParticipants = new address[](1);
        emergencyWithdrawParticipants[0] = address(alice);
        bootcamp.updateStatusBatch(emergencyWithdrawParticipants, DepositHandler.Status.Withdraw);
        bootcamp.pause();

        vm.stopPrank();

        vm.warp(bootcamp.bootcampStart() + bootcamp.withdrawDuration() - 1);

        // Try to withdraw and expect revert
        vm.prank(alice);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        bootcamp.withdraw();
    }

    function test_Withdrawal_Reverts_When_Period_Has_Ended() public {
        // Set up initial deposit for Alice
        vm.startPrank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();
        vm.stopPrank();

        // Manager updates Alice's status to "Withdraw" so she can withdraw
        vm.prank(manager);
        address[] memory emergencyWithdrawParticipants = new address[](1);
        emergencyWithdrawParticipants[0] = address(alice);
        bootcamp.updateStatusBatch(emergencyWithdrawParticipants, DepositHandler.Status.Withdraw);

        // Warp the time to just after the withdrawal period ends
        vm.warp(bootcamp.bootcampDeadline() + bootcamp.withdrawDuration() + 1);

        // Expect revert when Alice tries to withdraw after the period has finished
        vm.prank(alice);
        vm.expectRevert(IDepositHandlerErrors.DepositHandler__WithdrawStageAlreadyClosed.selector);
        bootcamp.withdraw();
    }

    /*//////////////////////////////////////////////////
               WithdrawAdmin FUNCTION TESTS
    /////////////////////////////////////////////////*/

    function test_WithdrawAdmin_Success() public {
        //set up initial deposit
        vm.startPrank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();
        vm.stopPrank();

        //simulate bootcamp finish and end of withdraw stage
        vm.warp(bootcamp.bootcampDeadline() + bootcamp.withdrawDuration() + 1);

        //attempt admin withdrawal from factory
        vm.prank(address(networkConfig.factory));
        uint256 remainingBalance = bootcamp.withdrawAdmin(manager, networkConfig.depositAmount);

        //verify manager received the funds
        assertEq(depositToken.balanceOf(manager), networkConfig.depositAmount);
        assertEq(remainingBalance, 0);
    }


    function test_WithdrawAdmin_Reverts_If_Not_Factory() public {
        vm.prank(alice);
        vm.expectRevert(IDepositHandlerErrors.DepositHandler__CallerNotAFactoryContract.selector);
        bootcamp.withdrawAdmin(manager, networkConfig.depositAmount);
    }


    function test_WithdrawAdmin_Reverts_If_Paused() public {
        //pause the contract
        vm.prank(manager);
        bootcamp.pause();

        vm.prank(address(networkConfig.factory));
        vm.expectRevert(bytes4(keccak256("EnforcedPause()")));
        bootcamp.withdrawAdmin(manager, networkConfig.depositAmount);
    }

    //function test_WithdrawAdmin_RevertsIfWithdrawStageNotFinished() public { THIS TEST IS TO CHECK THAT THE ADMIN CAN ONLY CALL AFTER THE WITHDRAW STAGE HAS FINISHED, HOWEVER A CHECK FOR THIS HAS NOT BEEN IMPLEMENTED YET
        //vm.prank(address(networkConfig.factory));
        //vm.expectRevert(IDepositHandlerErrors.DepositHandler__WithdrawStageAlreadyClosed.selector);
        //bootcamp.withdrawAdmin(manager, networkConfig.depositAmount);
    //}

    function test_WithdrawAdmin_Reverts_If_Amount_Exceeds_Balance() public {
        //simulate bootcamp finish and end of withdraw stage
        vm.warp(bootcamp.bootcampDeadline() + bootcamp.withdrawDuration() + 1);

        vm.prank(address(networkConfig.factory));
        vm.expectRevert(
            abi.encodeWithSelector(
                IDepositHandlerErrors.DepositHandler__IncorrectAmountForWithdrawal.selector, 
                type(uint256).max
            )
        );
        bootcamp.withdrawAdmin(manager, type(uint256).max);
    }



     /*//////////////////////////////////////////////////
               Exceptional WITHDRAW FUNCTION TESTS
    /////////////////////////////////////////////////*/
    function test_ExceptionalWithdraw_Success_WhenStatus_Is_Not_Changed() public {
        // alice deposits into the contract
        vm.startPrank(alice);
        //depositToken.mint(alice, 100);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();

        // manager withdraws on behalf of Alice 
        uint256 aliceBalanceBefore = depositToken.balanceOf(alice);
        //(uint256 aliceDepositBefore, ,DepositHandler.Status aliceStatusBefore) = bootcamp.deposits(alice);
        
        vm.startPrank(manager);
        bootcamp.exceptionalWithdraw(alice, DepositHandler.Status.InProgress);

        // verify that Alice's balance has been updated, her deposit reset to 0
        uint256 aliceBalanceAfter = depositToken.balanceOf(alice);
        (uint256 aliceDepositAfter, ,) = bootcamp.deposits(alice);
        
        assertEq(aliceDepositAfter, 0, "Alice's deposit should be 0 after withdrawal");
        assertEq(aliceBalanceAfter, aliceBalanceBefore + networkConfig.depositAmount, "Alice's balance should increase by the deposit amount");
        

        emit DepositWithdrawn(alice, networkConfig.depositAmount);
    }

    function test_ExceptionalWithdraw_Success_With_Passed_Status() public {
        // alice deposits into the contract
        vm.startPrank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();

        // manager withdraws on behalf of Alice and assigns 'Passed' status
        uint256 aliceBalanceBefore = depositToken.balanceOf(alice);
        //(uint256 aliceDepositBefore, ,DepositHandler.Status aliceStatusBefore) = bootcamp.deposits(alice);
        
        vm.startPrank(manager);
        bootcamp.exceptionalWithdraw(alice, DepositHandler.Status.Passed);

        // verify that Alice's balance has been updated, her deposit reset to 0, and status changed to passed
        uint256 aliceBalanceAfter = depositToken.balanceOf(alice);
        (uint256 aliceDepositAfter, ,DepositHandler.Status aliceStatusAfter) = bootcamp.deposits(alice);
        
        assertEq(aliceDepositAfter, 0, "Alice's deposit should be 0 after withdrawal");
        assertEq(aliceBalanceAfter, aliceBalanceBefore + networkConfig.depositAmount, "Alice's balance should increase by the deposit amount");
        assertEq(uint256(aliceStatusAfter), uint256(DepositHandler.Status.Passed), "Alice's status should be Passed");

        emit DepositWithdrawn(alice, networkConfig.depositAmount);
    }
        
     /*//////////////////////////////////////////////////
                Manager Assigning Status TESTS
    /////////////////////////////////////////////////*/

    function test_UpdateStatusBatch_Success() public {
        vm.startPrank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();

        vm.startPrank(bob);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();

        // manager updates status for both Alice and Bob to 'Passed'
        address[] memory participants = new address[](2);
        participants[0] = alice;
        participants[1] = bob;

        vm.startPrank(manager);
        bootcamp.updateStatusBatch(participants, DepositHandler.Status.Passed);

        // verify that both Alice's and Bob's status were updated
        ( ,, DepositHandler.Status aliceStatus) = bootcamp.deposits(alice);
        ( ,, DepositHandler.Status bobStatus) = bootcamp.deposits(bob);
        assertEq(uint256(aliceStatus), uint256(DepositHandler.Status.Passed), "Alice's status should be Passed");
        assertEq(uint256(bobStatus), uint256(DepositHandler.Status.Passed), "Bob's status should be Passed");
    }

    function test_UpdateStatusBatch_Revert_If_Empty_Array() public {
        // call the updateStatusBatch with an empty array
        address[] memory participants = new address[](0);

        vm.prank(manager);
        vm.expectRevert(IDepositHandlerErrors.DepositHandler__ParticipantsArraySizeIsZero.selector);
        bootcamp.updateStatusBatch(participants, DepositHandler.Status.Passed);
    }

    function test_UpdateStatusBatch_Revert_If_Non_Manager_Calls() public {
        address[] memory participants = new address[](2);
        participants[0] = alice;
        participants[1] = bob;

        // use the full AccessControlUnauthorizedAccount error selector
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")), 
                alice, 
                keccak256("MANAGER")
            )
        );
        bootcamp.updateStatusBatch(participants, DepositHandler.Status.Passed);
    }



    function test_UpdateStatusBatch_Revert_If_Participant_Address_Is_Zero() public {
        // set up a batch where one address is zero
        address[] memory participants = new address[](2);
        participants[0] = alice;
        participants[1] = address(0);

        // manager tries to update status, should revert due to zero address
        vm.prank(manager);
        vm.expectRevert(IDepositHandlerErrors.DepositHandler__UserAddressCanNotBeZero.selector);
        bootcamp.updateStatusBatch(participants, DepositHandler.Status.Passed);
    }


     /*//////////////////////////////////////////////////
                Pause and unpause TESTS
    /////////////////////////////////////////////////*/

    function test_Pause_Revert_If_Not_Manager() public {
        // try to pause the contract with a non-manager account
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")), 
                alice, 
                keccak256("MANAGER")
            )
        ); // Expect revert due to lack of MANAGER role
        bootcamp.pause();
    }


    function test_Unpause_Revert_If_Not_Manager() public {
        // manager pauses the contract first
        vm.prank(manager);
        bootcamp.pause();

        // try to unpause the contract with a non-manager account
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")), 
                alice, 
                keccak256("MANAGER")
            )
        ); // expect revert due to lack of MANAGER role
        bootcamp.unpause();
    }


    /*//////////////////////////////////////////////////
                Donate TESTS
    /////////////////////////////////////////////////*/


    function test_Participant_Can_Donate_Successfully() public {
        // Arrange: Make Alice a participant
        vm.startPrank(alice);
        depositToken.approve(address(bootcamp), networkConfig.depositAmount);
        bootcamp.deposit();  // Alice becomes a participant

        // Act: Alice donates
        bootcamp.donate();
        vm.stopPrank();

        // Assert: Verify donation status
        (, bool depositDonation,) = bootcamp.deposits(alice);
        assertTrue(depositDonation, "Donation status should be true after successful donation.");
    }

    function test_NonParticipant_Donation_Fails() public {
        // Act & Assert: Bob tries to donate but is not a participant
        vm.prank(bob);
        vm.expectRevert(IDepositHandlerErrors.DepositHandler__CallerNotParticipant.selector);
        bootcamp.donate();
    }   
}