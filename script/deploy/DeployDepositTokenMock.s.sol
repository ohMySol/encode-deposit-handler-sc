// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {DepositTokenMock} from "../../test/mocks/DepositTokenMock.sol";

contract DeployDepositTokenScript is Script {
   function run() public {
        deploy();
   }

   // Deploy script for DepositTokenMock.sol
   function deploy() public returns(DepositTokenMock, HelperConfig) {  
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

        vm.startBroadcast(config.admin);
        DepositTokenMock mock = new DepositTokenMock();
        vm.stopBroadcast();

        return (mock, helperConfig);
   }
}