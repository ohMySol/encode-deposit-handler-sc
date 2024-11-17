// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {DeployDepositHandlerScript} from "../script/deploy/DeployDepositHandler.s.sol";
import {IDepositHandlerErrors} from "../src/interfaces/ICustomErrors.sol";
import {DepositHandler} from "../src/DepositHandler.sol"; 
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract BootcampFactoryTest is Test {
    bytes32 public constant MANAGER = keccak256("MANAGER");
    bytes32 public constant INVALID_ROLE = bytes32("AVENGER");
    DepositHandler public bootcamp;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig networkConfig;
    
    address public manager;
    address public alice;

    event DepositDone(
        address depositor,
        uint256 depositAmount
    );
    event DepositWithdrawn(
        address depositor,
        uint256 withdrawAmount
    );

    function setUp() public {
        DeployDepositHandlerScript deployer = new DeployDepositHandlerScript();
        (bootcamp, helperConfig) = deployer.deploy(); // receive instances from deploy script based on the network
        networkConfig = helperConfig.getConfigByChainId(block.chainid);
        
        manager = vm.addr(networkConfig.manager); // manager who depployed a bootcamp contract
        alice = makeAddr(("alice")); // some other user without MANAGER role.
    }



    /*//////////////////////////////////////////////////
                INITIALIZATION TESTS
    /////////////////////////////////////////////////*/
    function test_DepositHandlerContractInitializedWithCorrectValues() public {
        console.log(manager);
        assertTrue(bootcamp.hasRole(MANAGER, manager));
        assertEq(bootcamp.depositAmount(), networkConfig.depositAmount);
        assertEq(address(bootcamp.depositToken()), networkConfig.depositToken);
        assertEq(bootcamp.bootcampStartTime(), networkConfig.bootcampStartTime);
    }
    
}
