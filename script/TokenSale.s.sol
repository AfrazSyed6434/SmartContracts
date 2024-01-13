// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "../src/TokenSale.sol";
import "../src/mock/MockToken.sol";


contract TokenSaleScript is Script {
    function setUp() public {}
    
    function run() public {
        uint256 deployer = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployer);

        MockToken token = new MockToken("Test Token", "TEST");
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
        TokenSale tokenSale = new TokenSale(
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
        token.mint(address(tokenSale), 150);
        tokenSale.transitionToNextStage();
        vm.stopBroadcast();
        // Lets buy some tokens for some ether
        buyTokens(tokenSale, 100);
        require(token.balanceOf(address(this)) == 5, "Token balance should be 5");
        
    

    }
    function buyTokens(TokenSale tokenSale,uint256 amount) public {
        tokenSale.buyTokens{value: amount}();
    }
}
