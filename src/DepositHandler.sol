// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DepositHandler {
    address public admin;
    IERC20 public usdcToken;
    mapping(address => uint256) public deposits; 
    mapping(address => bool) public bootcampCompleted;

    constructor(address _usdcToken) {
        admin = msg.sender;
        usdcToken = IERC20(_usdcToken);
    }

    // Allow users to deposit USDC
    function deposit(uint256 amount) external {
        require(amount >= 249e18 && amount <= 251e18, "Deposit must be 250USDC"); //we can change this if the deposit is different for different bootcamps
        require(usdcToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        deposits[msg.sender] += amount;
    }

    // Mark a user as having completed the bootcamp (only admin)
    function markBootcampComplete(address user) external {
        require(msg.sender == admin, "Only admin can mark completion"); //this could be done with a modifier instead to save gas?
        bootcampCompleted[user] = true;
    }

    // Withdraw funds if bootcamp is completed
    function withdraw() external {
        require(bootcampCompleted[msg.sender], "Bootcamp not successfully completed");
        uint256 depositAmount = deposits[msg.sender];
        require(depositAmount > 0, "No deposit to withdraw");

        deposits[msg.sender] = 0;  //prevent re-entrancy
        require(usdcToken.transfer(msg.sender, depositAmount), "Transfer failed");
    }
}
