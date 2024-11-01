// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";  
import "../src/DepositHandler.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; //used to create a mock USDC token for testing


contract MockUSDC is ERC20{ //mock token that simulates an ERC20 token
    constructor() ERC20("Mock USDC", "mUSDC"){
        _mint(msg.sender, 1000e18); //mint a 1000 ether
    }
}


contract DepositHandlerTest is Test {
    DepositHandler public depositHandler; //instance of the DepositHandler contract that is being tested
    MockUSDC public usdcToken;  // mock token for simulating deposits
    address user = address(1);  // simulated user address
    address admin = address(this); // admin is the contract deployer for testing


    function setUp() public {
    usdcToken = new MockUSDC(); // Deploy the mock USDC token
    depositHandler = new DepositHandler(address(usdcToken)); // Deploy the DepositHandler contract
}

    function testInitialSetup() public view {
        assertEq(depositHandler.admin(), admin, "Admin should be the contract deployer");
        assertEq(address(depositHandler.usdcToken()), address(usdcToken), "USDC token address should be correct");
    }

    function testDeposit() public {
    uint256 depositAmount = 250e18; // 250 USDC in token decimals
    usdcToken.transfer(user, depositAmount); //mint mock USDC to user

    
    vm.startPrank(user); //start simulating actions from the user's perspective
    usdcToken.approve(address(depositHandler), depositAmount); // approve the contract to spend the user's USDC
    depositHandler.deposit(depositAmount); //call the deposit function

    
    assertEq(depositHandler.deposits(user), depositAmount, "User deposit should be recorded"); //assert that the deposit was successfully recorded

    
    vm.stopPrank(); //stop simulating the user
}

}
