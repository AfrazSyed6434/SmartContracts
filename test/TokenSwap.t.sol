// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TokenSwap} from "../src/TokenSwap.sol";
import "src/mock/MockToken.sol";

contract TokenSaleTest is Test {
    TokenSwap public tokenSwap;
    MockToken public tokenA;
    MockToken public tokenB;

    function setUp() public {
        tokenA = new MockToken("TokenA", "TKA");
        tokenB = new MockToken("TokenB", "TKB");
        tokenSwap = new TokenSwap(tokenA, tokenB, 2, 5);
    }

    function test_swapAToB() public {
        tokenA.mint(address(this), 100);
        tokenA.approve(address(tokenSwap), 100);
        tokenB.mint(address(tokenSwap), 250);

        tokenSwap.swapAToB(100);

        assertEq(tokenA.balanceOf(address(this)), 0);
        assertEq(tokenB.balanceOf(address(this)), 250);
        assertEq(tokenA.balanceOf(address(tokenSwap)), 100);
        assertEq(tokenB.balanceOf(address(tokenSwap)), 0);
    }

    function test_swapBToA() public {
        tokenA.mint(address(tokenSwap), 100);
        tokenB.mint(address(this), 250);
        tokenB.approve(address(tokenSwap), 250);

        tokenSwap.swapBToA(250);

        assertEq(tokenA.balanceOf(address(this)), 100);
        assertEq(tokenB.balanceOf(address(this)), 0);
        assertEq(tokenA.balanceOf(address(tokenSwap)), 0);
        assertEq(tokenB.balanceOf(address(tokenSwap)), 250);
    }

    function test_swapAToBInvalidAmount() public {
        tokenA.mint(address(2), 100);
        tokenB.mint(address(tokenSwap), 250);

        vm.startBroadcast(address(2));

        tokenA.approve(address(tokenSwap), 100);
        vm.expectRevert("Invalid amount");
        tokenSwap.swapAToB(101);

        vm.stopBroadcast();
    }

    function test_swapAToBZeroAmount() public {
        tokenA.mint(address(2), 100);
        tokenB.mint(address(tokenSwap), 250);

        vm.startBroadcast(address(2));

        tokenA.approve(address(tokenSwap), 100);
        vm.expectRevert("Amount must be greater than zero");
        tokenSwap.swapAToB(0);

        vm.stopBroadcast();
    }

    function test_swapAToBInsufficientBalance() public {
        tokenA.mint(address(2), 100);
        tokenB.mint(address(tokenSwap), 240);

        vm.startBroadcast(address(2));

        tokenA.approve(address(tokenSwap), 100);
        vm.expectRevert("Insufficient balance");
        tokenSwap.swapAToB(100);

        vm.stopBroadcast();
    }

    function test_swapAToBInsufficientAllowance() public {
        tokenA.mint(address(2), 100);
        tokenB.mint(address(tokenSwap), 250);

        vm.startBroadcast(address(2));

        tokenA.approve(address(tokenSwap), 99);
        vm.expectRevert("Insufficient allowance");
        tokenSwap.swapAToB(100);

        vm.stopBroadcast();
    }

    function test_swapBToAInvalidAmount() public {
        tokenA.mint(address(tokenSwap), 100);
        tokenB.mint(address(2), 250);

        vm.startBroadcast(address(2));

        tokenB.approve(address(tokenSwap), 250);
        vm.expectRevert("Invalid amount");
        tokenSwap.swapBToA(251);

        vm.stopBroadcast();
    }

    function test_swapBToAZeroAmount() public {
        tokenA.mint(address(tokenSwap), 100);
        tokenB.mint(address(2), 250);

        vm.startBroadcast(address(2));

        tokenB.approve(address(tokenSwap), 250);
        vm.expectRevert("Amount must be greater than zero");
        tokenSwap.swapBToA(0);

        vm.stopBroadcast();
    }

    function test_swapBToAInsufficientBalance() public {
        tokenA.mint(address(tokenSwap), 99);
        tokenB.mint(address(2), 250);

        vm.startBroadcast(address(2));

        tokenB.approve(address(tokenSwap), 250);
        vm.expectRevert("Insufficient balance");
        tokenSwap.swapBToA(250);

        vm.stopBroadcast();
    }

    function test_swapBToAInsufficientAllowance() public {
        tokenA.mint(address(tokenSwap), 100);
        tokenB.mint(address(2), 250);

        vm.startBroadcast(address(2));

        tokenB.approve(address(tokenSwap), 249);
        vm.expectRevert("Insufficient allowance");
        tokenSwap.swapBToA(250);

        vm.stopBroadcast();
    }
}
