// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {DepositHandler} from "../../src/DepositHandler.sol";

contract DeployDepositHandlerScript is Script{
   function run() public {
      deploy();
   }

   // Deploy script for DepositHandler.sol
   function deploy() public returns(DepositHandler, HelperConfig) {
      HelperConfig helperConfig = new HelperConfig();
      HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

      vm.startBroadcast(config.manager);
        DepositHandler depositHandler = new DepositHandler(
            config.depositAmount,
            config.depositToken,
            vm.addr(config.manager),
            config.bootcampStart,
            config.bootcampDeadline,
            config.withdrawDuration,
            config.factory,
            config.bootcampName
        );
        vm.stopBroadcast();

        return (depositHandler, helperConfig);
   }
}