// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {DepositHandler} from "../src/DepositHandler.sol";

contract DepositHandlerTest is Test {
    DepositHandler public depositHandler;

    function setUp() public {
        depositHandler = new DepositHandler();
    }
}
