// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {DepositTokenMock} from "../test/mocks/DepositTokenMock.sol";
import {IHelperConfigErrors} from "../src/interfaces/ICustomErrors.sol";

abstract contract Constants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant POL_AMOY_CHAIN_ID = 80002;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, Constants, IHelperConfigErrors {
    struct NetworkConfig {
        address depositToken;
        uint256 depositAmount;
        address manager;
        uint256 bootcampStartTime;
    }

    NetworkConfig public localNetworkConfig;

    mapping (uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[LOCAL_CHAIN_ID] = getLocalNetworkConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 _chainId) public returns (NetworkConfig memory) {
        if(networkConfigs[_chainId].depositToken != address(0)) {
            return networkConfigs[_chainId];
        } else if (_chainId == LOCAL_CHAIN_ID) {
            return getLocalNetworkConfig();
        } else {
            revert HelperConfig_NotSupportedChain();
        }
    }

    // Return a config for local testing/interraction with DepositHandler.sol
    function getLocalNetworkConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.depositToken != address(0)) {
            return localNetworkConfig;
        } else {
            // deploy mocks
            vm.startBroadcast();
            DepositTokenMock tokenMock = new DepositTokenMock();
            vm.stopBroadcast();

            localNetworkConfig = NetworkConfig({
                depositToken: address(tokenMock),
                depositAmount: 100,
                manager: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, // account from anvil list
                bootcampStartTime: block.timestamp + 30 seconds
            });
            return localNetworkConfig;
        }
    }

    function getAmoyNetworkConfig() public returns(NetworkConfig memory) {
    }

    function getSepoliaNetworkConfig() public returns(NetworkConfig memory) {
    }
}