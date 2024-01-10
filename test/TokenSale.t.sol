// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TokenSale} from "../src/TokenSale.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./mock/MockToken.sol";

contract TokenSaleTest is Test {
    TokenSale public tokenSale;
    MockToken public token;

    function setUp() public {
        token = new MockToken("Test Token", "TEST");
        tokenSale = new TokenSale(token, 1, 100, 1, 20);
        token.mint(address(tokenSale), 100);
    }

    function test_buyTokens() public {
        tokenSale.buyTokens{value: 10}();
        assertEq(token.balanceOf(address(tokenSale)), 90);
        assertEq(token.balanceOf(address(this)), 10);
    }

    function test_buyTokens_WithMaxContribution() public {
        vm.expectEmit();
        emit TokenSale.TokenPurchase(address(this), 20, 20);
        tokenSale.buyTokens{value: 20}();
        assertEq(token.balanceOf(address(tokenSale)), 80);
        assertEq(token.balanceOf(address(this)), 20);
    }

    function test_buyTokens_ExceedMaxContribution() public {
        vm.expectRevert("Invalid contribution amount");
        tokenSale.buyTokens{value: 21}();
    }

    // Now i want to test what if 5 different users buy 20 tokens each and then 6th tries to exceed the sales cap
    function test_buyTokens_WithMultipleUsers() public {
        setUpUsers();
        tokenSale.buyTokens{value: 20}();
        assertEq(token.balanceOf(address(tokenSale)), 80);
        vm.prank(address(2));
        tokenSale.buyTokens{value: 20}();
        assertEq(token.balanceOf(address(tokenSale)), 60);
        vm.prank(address(3));
        tokenSale.buyTokens{value: 20}();
        assertEq(token.balanceOf(address(tokenSale)), 40);
        vm.prank(address(4));
        tokenSale.buyTokens{value: 20}();
        assertEq(token.balanceOf(address(tokenSale)), 20);
        vm.prank(address(5));
        tokenSale.buyTokens{value: 20}();
        assertEq(token.balanceOf(address(tokenSale)), 0);
    }

    function testFail_exceedSalesCap() public {
        setUpUsers();
        tokenSale.buyTokens{value: 20}();
        vm.prank(address(2));
        tokenSale.buyTokens{value: 20}();
        vm.prank(address(3));
        tokenSale.buyTokens{value: 20}();
        vm.prank(address(4));
        tokenSale.buyTokens{value: 20}();
        vm.prank(address(5));
        tokenSale.buyTokens{value: 20}();
        vm.prank(address(6));
        tokenSale.buyTokens{value: 20}();
    }

    function setUpUsers() public {
        payable(address(2)).transfer(20);
        payable(address(3)).transfer(20);
        payable(address(4)).transfer(20);
        payable(address(5)).transfer(20);
        payable(address(6)).transfer(20);
    }
}
