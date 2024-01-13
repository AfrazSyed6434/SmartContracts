// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "../src/TokenSwap.sol";
import "../src/mock/MockToken.sol";


contract TokenSwapScript is Script {
    TokenSwap public tokenSwap;
    MockToken public tokenA;
    MockToken public tokenB;
    function setUp() public {}
    
    function run() public {
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployer);
        tokenA = new MockToken("TokenA", "TKA");
        tokenB = new MockToken("TokenB", "TKB");
        tokenSwap = new TokenSwap(tokenA, tokenB, 2, 5);
        tokenA.mint(address(this), 100);
        tokenB.mint(address(tokenSwap), 250);
        vm.stopBroadcast();
        tokenA.approve(address(tokenSwap), 100);
        swapAToB(100);

    }
    function swapAToB(uint256 amount) public {
        tokenSwap.swapAToB(amount);
    }
    
}
