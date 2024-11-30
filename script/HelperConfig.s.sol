// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {DepositTokenMock} from "../test/mocks/DepositTokenMock.sol";
import {BootcampFactory} from "../src/BootcampFactory.sol";
import {IHelperConfigErrors} from "../src/interfaces/ICustomErrors.sol";

abstract contract Constants {
    uint256 public constant POL_AMOY_CHAIN_ID = 80002;
    uint256 public constant TN_POL_MAINNET_FORK_CHAIN_ID = 25112000; // please set up here your custom chain id from Tenderly virtual network
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, Constants, IHelperConfigErrors {
    struct NetworkConfig {
        uint256 depositAmount;
        address depositToken;
        uint256 bootcampStart;
        uint256 bootcampDeadline;
        uint256 withdrawDuration;
        address factory;
        string bootcampName;
        uint256 admin;
        uint256 manager;
    }

    /**
     * @dev Allows to receive a config for deployment/tests/scripts based on the chain you are.
     * 
     * @param _chainId - id of your chain you are working on.
     * @param _isDepositHandler - flag which shows if we getting a config for `DepositHandler` contract or no.
     * if `true`, then `BootcampFactory` instance will deployed, and vice versa.
     */
    function getConfigByChainId(uint256 _chainId, bool _isDepositHandler) public returns (NetworkConfig memory) {
        if (_chainId == LOCAL_CHAIN_ID) {
            return getLocalNetworkConfig(_isDepositHandler);
        } else if (_chainId == TN_POL_MAINNET_FORK_CHAIN_ID) {
            return getPolygonMainnetForkNetworkConfig();
        } else if (_chainId == POL_AMOY_CHAIN_ID) {
            return getPolygonAmoyNetworkConfig();
        } else {
            revert HelperConfig_NotSupportedChain();
        }
    }

    /**
     * @dev Returns a config with necessary parameters for local deployment/interraction/testing.
     * Instructions:
     *  - `depositToken` parameter will be deployed automatically when receiving this config.
     *  - `admin` and `manager` are 2 private keys I took from the anvile test accounts list.
     *  Spin up Anvil and take w private keys you want and paste them in your .env file.
     *  - `depositAmount` - feel free to change.
     *  - `bootcampStart` - feel free to change.
     *  - `bootcampDeadline` - feel free to change.
     *  - `withdrawDuration` - feel free to change.
     *   - `bootcampName` - feel free to change.
     * 
     * @param _isDepositHandler - flag which shows if we getting a config for `DepositHandler` contract or no.
     * if `true`, then `BootcampFactory` instance will deployed, and vice versa. 
     * 
     * @return NetworkConfig structure is returned.
     */
    function getLocalNetworkConfig(bool _isDepositHandler) public returns (NetworkConfig memory) {
        uint256 _bootcampStart = block.timestamp + 10 minutes;
        BootcampFactory factory;

        vm.startBroadcast();
            DepositTokenMock tokenMock = new DepositTokenMock();
            if (_isDepositHandler) { // deploy a BootcampFactory instance only if config used in DepositHandler.
                factory = new BootcampFactory();                
            }
        vm.stopBroadcast();

        NetworkConfig memory localNetworkConfig = NetworkConfig({
            depositAmount: 100000000,
            depositToken: address(tokenMock),
            bootcampStart: _bootcampStart,
            bootcampDeadline: _bootcampStart + 10 minutes,
            withdrawDuration: 10 minutes,
            factory: _isDepositHandler ? address(factory) : address(0),
            bootcampName: "G5",
            manager: vm.envUint("MANAGER_LOCAL_PK"), // pk from anvil list
            admin: vm.envUint("ADMIN_LOCAL_PK") // pk from anvil list
        });

        return localNetworkConfig;
    }

    /**
     * @dev Returns a config with necessary parameters for Tenderly fork network deployment/interraction/testing.
     * Instructions:
     *  - `depositToken` deploy token mock to Tenderly virtual network and set contract address in config.
     *  - `admin`
     *  - `manager`
     *  - `depositAmount` - feel free to change.
     *  - `bootcampStart` - feel free to change.
     *  - `bootcampDeadline` - feel free to change.
     *  - `withdrawDuration` - feel free to change.
     *  - `factory` - deploy BootcampFactory to Tenderly virtual network and set contract address in config.
     *   - `bootcampName` - feel free to change.
     * 
     * @return NetworkConfig structure is returned.
     */
    function getPolygonMainnetForkNetworkConfig() public view returns(NetworkConfig memory) {
        uint256 _bootcampStart = block.timestamp + 10 minutes;
        NetworkConfig memory tenderlyNetworkConfig = NetworkConfig({
            depositAmount: 100000000,
            depositToken: address(0), // set your token mock address on Tenderly virtual network
            bootcampStart: _bootcampStart,
            bootcampDeadline: _bootcampStart + 10 minutes,
            withdrawDuration: 10 minutes,
            factory: address(0), // set your bootcamp factory address on Tenderly virtual network
            bootcampName: "G5",
            manager: vm.envUint("MANAGER_LOCAL_PK"), // pk from anvil list
            admin: vm.envUint("TN_FORK_POL_MAINNET_ADMIN_PK")
        });

        return tenderlyNetworkConfig;
    }

    /**
     * @dev Returns a config with necessary parameters for Amoy testnet deployment/interraction/testing.
     * Instructions:
     *  - `depositToken` deploy token mock to Amoy virtual network and set contract address in config.
     *  - `admin`
     *  - `manager`
     *  - `depositAmount` - feel free to change.
     *  - `bootcampStart` - feel free to change.
     *  - `bootcampDeadline` - feel free to change.
     *  - `withdrawDuration` - feel free to change.
     *  - `factory` - deploy BootcampFactory to Amoy virtual network and set contract address in config.
     *   - `bootcampName` - feel free to change.
     * 
     * @return NetworkConfig structure is returned.
     */
    function getPolygonAmoyNetworkConfig() public view returns(NetworkConfig memory) {
        uint256 _bootcampStart = block.timestamp + 10 minutes;
        NetworkConfig memory amoyNetworkConfig = NetworkConfig({
            depositAmount: 100000000,
            depositToken: address(0), // set your token mock address on Amoy network
            bootcampStart: _bootcampStart,
            bootcampDeadline: _bootcampStart + 10 minutes,
            withdrawDuration: 10 minutes,
            factory: address(0), // set your bootcamp factory address on Amoy network
            bootcampName: "G5",
            manager: vm.envUint("MANAGER_LOCAL_PK"), // pk from anvil list
            admin: vm.envUint("AMOY_ADMIN_PK")
        });

        return amoyNetworkConfig;
    }
}