// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {BootcampFactory} from "../../src/BootcampFactory.sol";

contract DeployBootcampFactoryScript is Script {
   function run() public {
        deploy();
   }

   // Deploy script for BootcampFactory.sol
   function deploy() public returns(BootcampFactory, HelperConfig.NetworkConfig memory) {  
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

        vm.startBroadcast(config.admin);
        BootcampFactory factory = new BootcampFactory();
        vm.stopBroadcast();

        console.log("BootcampFactory contract deployed at: ", address(factory));

        return (factory, config);
   }
}