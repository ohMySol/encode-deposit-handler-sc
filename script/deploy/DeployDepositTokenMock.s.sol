// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {DepositTokenMock} from "../../test/mocks/DepositTokenMock.sol";

contract DeployDepositTokenMockScript is Script {
   address[] testAccounts;

   function run() public {
        deploy();
   }

   // Deploy script for DepositTokenMock.sol
   function deploy() public returns(DepositTokenMock) {
        vm.startBroadcast();
        DepositTokenMock tokenMock = new DepositTokenMock();
        vm.stopBroadcast();

        return tokenMock;
   }
}