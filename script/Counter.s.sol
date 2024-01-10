// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "../src/Counter.sol";

contract CounterScript is Script {
    function setUp() public {}
    
    function run() public {
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        vm.broadcast(deployer);
        // Create an instance of the smart contract (doing that will deploy the contract when the script runs)
        Counter counter = new Counter();
        uint256 number = counter.number();
        console2.logUint(number);
        // Call the setNumber function
        counter.setNumber(42);
        number = counter.number();
        console2.logUint(number);
    }
}
