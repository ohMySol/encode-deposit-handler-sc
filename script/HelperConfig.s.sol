// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";

abstract contract Constants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant POL_AMOY_CHAIN_ID = 80002;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}
contract HelperConfig is Script {
    struct NetworkConfig {
        address depositToken;
        address manager;
        uint256 depositAmount;
        uint256 bootcampDuration;
        uint256 bootcampStartTime;
    }

    NetworkConfig public localNetworkConfig;

    mapping (uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        
    }
}