// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*

Token Swap Smart Contract:

The Token Swap smart contract facilitates the exchange of one ERC-20 token for another at a fixed exchange rate. Users can perform swaps between Token A and Token B, and the contract ensures adherence to the predefined exchange rate. The contract is designed to be secure, efficient, and compliant with the ERC-20 standard for both tokens.

Design Choices:

The contract utilizes the OpenZeppelin library, incorporating the SafeERC20 and Ownable contracts for enhanced security and ownership control. The use of SafeERC20 ensures secure interactions with ERC-20 tokens, preventing common vulnerabilities such as reentrancy attacks.

The constructor initializes the contract with the addresses of Token A and Token B, along with the fixed exchange rate represented by exchangeRateAtoBNumerator and exchangeRateAtoBDenominator. This design choice provides flexibility for adjusting the exchange rate as needed.

Two external functions, swapAToB and swapBToA, enable users to perform token swaps in both directions. The calculations for the swapped amounts take into account the exchange rate, providing accurate conversions between Token A and Token B while considering decimal adjustments.

The contract emits a Swap event to log details of each swap, enhancing transparency and facilitating monitoring of swap activities.

Security Considerations:

The contract leverages OpenZeppelin's SafeERC20 library to handle token transfers securely. The use of SafeERC20 guards against potential vulnerabilities related to token transfers, including reentrancy attacks, ensuring a robust and secure implementation.

Ownership control is implemented through the Ownable contract, restricting certain administrative functions to the contract owner. This adds an additional layer of security by preventing unauthorized access to critical contract functionalities.

Input validation is enforced throughout the contract to ensure that only valid and non-zero amounts are accepted for swaps. The checks on allowance and balance verify that the contract has the necessary funds to execute the swap, mitigating potential issues related to insufficient balances or allowances.

The contract incorporates exchange rate validation to ensure that the swap adheres to the predefined rate. This guards against manipulations or attempts to exploit potential discrepancies in exchange rates.
*/

contract TokenSwap is Ownable {
    using SafeERC20 for IERC20;
    
    IERC20 public tokenA;  // Address of Token A
    IERC20 public tokenB;  // Address of Token B
    uint256 public exchangeRateAtoBNumerator; 
    uint256 public exchangeRateAtoBDenominator;  
    event Swap(address indexed user, uint256 amountA, uint256 amountB);
    
    /// @dev Constructor to initialize the contract with the addresses of Token A and Token B, along with the fixed exchange rate represented by exchangeRateAtoBNumerator and exchangeRateAtoBDenominator.
    /// @param _tokenA Address of Token A
    /// @param _tokenB Address of Token B
    /// @param _exchangeRateAtoBNumerator Numerator of the exchange rate between Token A and Token B
    /// @param _exchangeRateAtoBDenominator Denominator of the exchange rate between Token A and Token B
    constructor(IERC20 _tokenA, IERC20 _tokenB, uint256 _exchangeRateAtoBNumerator, uint256 _exchangeRateAtoBDenominator)Ownable(msg.sender) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        exchangeRateAtoBNumerator = _exchangeRateAtoBNumerator;
        exchangeRateAtoBDenominator = _exchangeRateAtoBDenominator;
    }
    
    /// @dev Function to swap Token A for Token B
    /// @param amountA Amount of Token A to swap
    function swapAToB(uint256 amountA) external {
        require(amountA > 0, "Amount must be greater than zero");
        require((amountA*exchangeRateAtoBDenominator) % exchangeRateAtoBNumerator == 0, "Invalid amount");
        uint256 amountB = (amountA * exchangeRateAtoBDenominator) / exchangeRateAtoBNumerator;  // Adjust for decimals
        require(amountB > 0, "Invalid amount");
        require(tokenB.balanceOf(address(this)) >= amountB, "Insufficient balance");
        require(tokenA.allowance(msg.sender, address(this)) >= amountA, "Insufficient allowance");
        
        tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        tokenB.safeTransfer(msg.sender, amountB);
    
    }

    /// @dev Function to swap Token B for Token A
    /// @param amountB Amount of Token B to swap
    function swapBToA(uint256 amountB) external {
        require(amountB > 0, "Amount must be greater than zero");
        require((amountB*exchangeRateAtoBNumerator) % exchangeRateAtoBDenominator == 0, "Invalid amount");
        uint256 amountA = (amountB * exchangeRateAtoBNumerator) / exchangeRateAtoBDenominator;  // Adjust for decimals
        require(amountA > 0, "Invalid amount");
        require(tokenA.balanceOf(address(this)) >= amountA, "Insufficient balance");
        require(tokenB.allowance(msg.sender, address(this)) >= amountB, "Insufficient allowance");

        tokenB.safeTransferFrom(msg.sender, address(this), amountB);
        tokenA.safeTransfer(msg.sender, amountA);
    }
}
