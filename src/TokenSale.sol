// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenSale is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public ethToTokenMultiplier;
    uint256 public saleMaxCap;
    uint256 public minContribution;
    uint256 public maxContribution;

    bool public saleEnded = false;

    mapping(address => uint256) public contributions;

    event TokenPurchase(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);

    modifier onlyWhileSaleOpen() {
        require(!saleEnded, "Sale has ended");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Not admin");
        _;
    }

    modifier onlyAfterSale() {
        require(saleEnded, "Sale has not ended");
        _;
    }

    constructor(
        IERC20 _token,
        uint256 _ethToTokenMultiplier,
        uint256 _saleMaxCap,
        uint256 _minContribution,
        uint256 _maxContribution
    ) {
        require(_ethToTokenMultiplier > 0, "Multiplier must be greater than zero");
        require(_saleMaxCap > 0, "Sale max cap must be greater than zero");
        require(_minContribution > 0, "Min contribution must be greater than zero");
        require(_maxContribution >= _minContribution, "Max contribution must be greater than or equal to min contribution");

        token = _token;
        ethToTokenMultiplier = _ethToTokenMultiplier;
        saleMaxCap = _saleMaxCap;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
    }

    function buyTokens() external payable onlyWhileSaleOpen {
        require(msg.value >= minContribution, "Below min contribution");
        require(msg.value <= maxContribution, "Exceeds max contribution");

        uint256 tokensToPurchase = msg.value.mul(ethToTokenMultiplier);
        require(token.balanceOf(address(this)) >= tokensToPurchase, "Not enough tokens left for sale");

        require(contributions[msg.sender].add(msg.value) <= maxContribution, "Exceeds max contribution for this address");

        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        emit TokenPurchase(msg.sender, msg.value, tokensToPurchase);

        token.transfer(msg.sender, tokensToPurchase);
    }

    function endSale() external onlyAdmin {
        saleEnded = true;
    }

    function changeMultiplier(uint256 _newMultiplier) external onlyAdmin {
        require(_newMultiplier > 0, "Multiplier must be greater than zero");
        ethToTokenMultiplier = _newMultiplier;
    }

    // In case tokens are sent to this contract by mistake, the admin can withdraw them
    function withdrawExcessTokens() external onlyAdmin onlyAfterSale {
        uint256 excessTokens = token.balanceOf(address(this)).sub(saleMaxCap);
        if (excessTokens > 0) {
            token.transfer(owner(), excessTokens);
        }
    }

    // In case there is remaining ether in the contract, the admin can withdraw it after the sale has ended
    function withdrawExcessEther() external onlyAdmin onlyAfterSale {
        uint256 excessEther = address(this).balance;
        if (excessEther > 0) {
            payable(owner()).transfer(excessEther);
        }
    }
}