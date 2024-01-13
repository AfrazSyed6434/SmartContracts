// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TokenSale} from "../src/TokenSale.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/mock/MockToken.sol";

contract TokenSaleTest is Test {
    TokenSale public tokenSale;
    MockToken public token;
    
    function setUp() public {
        token = new MockToken("Test Token", "TEST");
        uint256 preSalePrice = 20;
        uint256 publicSalePrice = 30;
        uint256 preSaleMinSalesCap = 10;
        uint256 publicSaleMinSalesCap = 10;
        uint256 preSaleMaxSalesCap = 50;
        uint256 publicSaleMaxSalesCap = 100;
        uint256 preSaleMinContribution = 20;
        uint256 publicSaleMinContribution = 30;
        uint256 preSaleMaxContribution = 200;
        uint256 publicSaleMaxContribution = 300;
        tokenSale = new TokenSale(
            token,
            preSalePrice,
            publicSalePrice,
            preSaleMinSalesCap,
            publicSaleMinSalesCap,
            preSaleMaxSalesCap,
            publicSaleMaxSalesCap,
            preSaleMinContribution,
            publicSaleMinContribution,
            preSaleMaxContribution,
            publicSaleMaxContribution
        );
        token.mint(address(this), 150);
        token.approve(address(tokenSale), 150);
        tokenSale.addTokens(150);
    }

    function test_checkPrice() public {
        
        assertEq(tokenSale.getCurrentPrice(), 0);
        tokenSale.transitionToNextStage();
        assertEq(tokenSale.getCurrentPrice(), 20);
        tokenSale.transitionToNextStage();
        assertEq(tokenSale.getCurrentPrice(), 30);
        tokenSale.transitionToNextStage();
        assertEq(tokenSale.getCurrentPrice(), 0);
    
    }
    
    function test_buyTokens() public {
        tokenSale.transitionToNextStage();
        tokenSale.buyTokens{value: 20}();
        assertEq(token.balanceOf(address(tokenSale)), 149);
        assertEq(token.balanceOf(address(this)), 1);
    }

    function test_buyTokensWithoutSaleStarted() public {
        vm.expectRevert("Sale has not started");
        tokenSale.buyTokens{value: 20}();
    }

    function test_buyTokensAfterSaleEnded() public {
        tokenSale.transitionToNextStage();
        tokenSale.transitionToNextStage();
        tokenSale.transitionToNextStage();
        vm.expectRevert("Sale has ended");
        tokenSale.buyTokens{value: 20}();
    }
    
    function test_buyTokensWithMaxContributionPreSale() public {
        tokenSale.transitionToNextStage();
        vm.expectEmit(address(tokenSale));
        emit TokenSale.TokenPurchase(address(this), 200, 10,TokenSale.SaleStage.PreSale);
        tokenSale.buyTokens{value: 200}();
        assertEq(token.balanceOf(address(tokenSale)), 140);
        assertEq(token.balanceOf(address(this)), 10);
    }

    function test_buyTokensWithMaxContributionPublicSale() public {
        tokenSale.transitionToNextStage();
        tokenSale.transitionToNextStage();
        vm.expectEmit(address(tokenSale));
        emit TokenSale.TokenPurchase(address(this), 300, 10,TokenSale.SaleStage.PublicSale);
        tokenSale.buyTokens{value: 300}();
        assertEq(token.balanceOf(address(tokenSale)), 140);
        assertEq(token.balanceOf(address(this)), 10);
    }
    
    function test_buyTokensExceedMaxContributionPreSale() public {
        tokenSale.transitionToNextStage();
        vm.expectRevert("Exceeds max contribution");
        tokenSale.buyTokens{value: 201}();
    }
    
    function test_buyTokensExceedMaxContributionPublicSale() public {
        tokenSale.transitionToNextStage();
        tokenSale.transitionToNextStage();
        vm.expectRevert("Exceeds max contribution");
        tokenSale.buyTokens{value: 301}();
    }
    
    function test_buyTokensUnderMinContributionPreSale() public {
        tokenSale.transitionToNextStage();
        vm.expectRevert("Below min contribution");
        tokenSale.buyTokens{value: 19}();
    }

    function test_buyTokensUnderMinContributionPublicSale() public {
        tokenSale.transitionToNextStage();
        tokenSale.transitionToNextStage();
        vm.expectRevert("Below min contribution");
        tokenSale.buyTokens{value: 29}();
    }

    function test_buyTokensInvalidAmountPreSale() public {
        tokenSale.transitionToNextStage();
        vm.expectRevert("Invalid contribution amount. Ensure msg.value is a multiple of the price");
        tokenSale.buyTokens{value: 45}();
    }
    
    function test_buyTokensInvalidAmountPublicSale() public {
        tokenSale.transitionToNextStage();
        tokenSale.transitionToNextStage();
        vm.expectRevert("Invalid contribution amount. Ensure msg.value is a multiple of the price");
        tokenSale.buyTokens{value: 65}();
    }
    // // Now i want to test what if 5 different users buy 20 tokens each and then 6th tries to exceed the sales cap
    function test_buyTokens_WithMultipleUsers() public {
        tokenSale.transitionToNextStage();
        setUpUsers();

        tokenSale.buyTokens{value: 200}();
        assertEq(token.balanceOf(address(this)), 10);
        assertEq(token.balanceOf(address(tokenSale)), 140);
    
        vm.prank(address(2));
        tokenSale.buyTokens{value: 200}();
        assertEq(token.balanceOf(address(2)), 10); 
        assertEq(token.balanceOf(address(tokenSale)), 130);
        
        vm.prank(address(3));
        tokenSale.buyTokens{value: 200}();
        assertEq(token.balanceOf(address(3)), 10);
        assertEq(token.balanceOf(address(tokenSale)), 120);
        
        vm.prank(address(4));
        tokenSale.buyTokens{value: 180}();
        assertEq(token.balanceOf(address(4)), 9);
        assertEq(token.balanceOf(address(tokenSale)), 111);
        
        vm.prank(address(5));
        tokenSale.buyTokens{value: 140}();
        assertEq(token.balanceOf(address(5)), 7);
        assertEq(token.balanceOf(address(tokenSale)), 104);
    }

    function test_exceedSalesCap() public {
        tokenSale.transitionToNextStage();
        setUpUsers();

        tokenSale.buyTokens{value: 200}();
    
        vm.prank(address(2));
        tokenSale.buyTokens{value: 200}();
        
        vm.prank(address(3));
        tokenSale.buyTokens{value: 200}();
        
        vm.prank(address(4));
        tokenSale.buyTokens{value: 200}();
        
        vm.prank(address(5));
        tokenSale.buyTokens{value: 200}();
        
        vm.prank(address(6));
        vm.expectRevert("Exceeds max sales cap");
        tokenSale.buyTokens{value: 200}();
    }

    function test_claimRefundFromPresale() public {
        uint256 balance = address(this).balance;
        
        tokenSale.transitionToNextStage();
        tokenSale.buyTokens{value: 180}();
        
        assertEq(address(this).balance, balance - 180);
        assertEq(token.balanceOf(address(this)), 9);
        assertEq(token.balanceOf(address(tokenSale)), 141);
        
        tokenSale.transitionToNextStage();    
        token.approve(address(tokenSale), 9);  
        tokenSale.claimRefund();
    
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(tokenSale)), 150);
        assertEq(address(this).balance, balance);
    }
    function test_claimRefundFromPublicSale() public {
        uint256 balance = address(this).balance;

        tokenSale.transitionToNextStage();
        tokenSale.transitionToNextStage();
        tokenSale.buyTokens{value: 180}();
        
        assertEq(address(this).balance, balance - 180);
        assertEq(token.balanceOf(address(this)), 6);
        assertEq(token.balanceOf(address(tokenSale)), 144);
        
        tokenSale.transitionToNextStage();    
        token.approve(address(tokenSale), 6);  
        tokenSale.claimRefund();
    
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(tokenSale)), 150);
        assertEq(address(this).balance, balance);
    }
    function test_claimRefundPreSaleMinSalesCapReached() public {
        tokenSale.transitionToNextStage();
        setUpUsers();
        
        tokenSale.buyTokens{value: 200}();
        assertEq(token.balanceOf(address(this)), 10);
        assertEq(token.balanceOf(address(tokenSale)), 140);
        
        tokenSale.transitionToNextStage();    
        token.approve(address(tokenSale), 50);  
        
        vm.expectRevert("No refund available. All sales met min cap or sale has not ended");
        tokenSale.claimRefund();
    
        assertEq(token.balanceOf(address(this)), 10);
        assertEq(token.balanceOf(address(tokenSale)), 140);
    }
    function test_claimRefundPublicSaleMinSalesCapReached() public {
        tokenSale.transitionToNextStage();
        tokenSale.transitionToNextStage();
        setUpUsers();
        
        tokenSale.buyTokens{value: 300}();
        assertEq(token.balanceOf(address(this)), 10);
        assertEq(token.balanceOf(address(tokenSale)), 140);

        tokenSale.transitionToNextStage();    
        token.approve(address(tokenSale), 10);  

        vm.expectRevert("No refund available. All sales met min cap or sale has not ended");
        tokenSale.claimRefund();
    
        assertEq(token.balanceOf(address(this)), 10);
        assertEq(token.balanceOf(address(tokenSale)), 140);
    }
    function test_claimRefundPreSaleWithoutApproval() public {
        uint256 balance = address(this).balance;
        
        tokenSale.transitionToNextStage();
        tokenSale.buyTokens{value: 180}();
        
        assertEq(address(this).balance, balance - 180);
        assertEq(token.balanceOf(address(this)), 9);
        assertEq(token.balanceOf(address(tokenSale)), 141);
        
        tokenSale.transitionToNextStage();    

        vm.expectRevert("Approve tokenSale to transfer tokens back");
        tokenSale.claimRefund();
    
        assertEq(token.balanceOf(address(this)), 9);
        assertEq(token.balanceOf(address(tokenSale)), 141);
        assertEq(address(this).balance, balance - 180);
    }
    
    // function test_claimRefundAfterMinCapReached() public {
    //     buyTillSalesMinCap();
    //     tokenSale.endSale();
        
    //     vm.prank(address(2));
    //     token.approve(address(tokenSale), 20);  
        
    //     vm.expectRevert("Sales Min Cap reached");
    //     vm.prank(address(2));
    //     tokenSale.claimRefund();
    // }

    // function test_claimRefundWithoutAllowance() public {
        
    //     tokenSale.buyTokens{value: 20}();
        
    //     vm.expectRevert("Approve tokenSale to transfer tokens back");
    //     tokenSale.claimRefund();
    // }
    
    function setUpUsers() public {
        payable(address(2)).transfer(200);
        payable(address(3)).transfer(200);
        payable(address(4)).transfer(200);
        payable(address(5)).transfer(200);
        payable(address(6)).transfer(200);
    }
    // function buyTillSalesMinCap() public {
    //     setUpUsers();
    //     vm.prank(address(2));
    //     tokenSale.buyTokens{value: 20}();
    //     vm.prank(address(3));
    //     tokenSale.buyTokens{value: 20}();
    //     vm.prank(address(4));
    //     tokenSale.buyTokens{value: 20}();
    // }
     // Function to receive Ether. msg.data must be empty
    receive() external payable {}

}
