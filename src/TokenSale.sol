// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TokenSale
 * @dev A smart contract for conducting a two-phase token sale: presale and public sale.
 */
contract TokenSale is Ownable, ReentrancyGuard {

    // Constants to represent the different stages of the sale

    bytes32 public constant PRE_SALE = keccak256("PRE_SALE");
    bytes32 public constant PUBLIC_SALE = keccak256("PUBLIC_SALE");

    // ERC-20 token being sold
    IERC20 public token;

    // Enum to represent different stages of the sale
    enum SaleStage {
        NotStarted,
        PreSale,
        PublicSale,
        EndSale
    }

    // Struct to store sale details for each stage
    struct Sale {
        uint256 price;            // Token price in Ether
        uint256 maxSalesCap;      // Maximum Ether that can be raised in the sale
        uint256 minSalesCap;      // Minimum Ether required to consider the sale successful
        uint256 totalSales;       // Total tokens sold in the sale
        uint256 minContribution;  // Minimum contribution amount per participant
        uint256 maxContribution;  // Maximum contribution amount per participant
    }

    // Current stage of the sale
    SaleStage public currentStage = SaleStage.NotStarted;

    // Mapping to store sale details for each stage
    mapping(bytes32 => Sale) public saleDetails;

    // Mapping to store contributions for each participant in each stage
    mapping(address => mapping(bytes32 => uint256)) public saleContributions;

    // Events to log major contract activities
    event TokenPurchase(
        address indexed buyer,
        uint256 ethAmount,
        uint256 tokenAmount,
        SaleStage saleStage
    );
    event StageChanged(SaleStage newStage);

    // Modifiers for access control
    modifier onlyWhileSaleOpen() {
        require(currentStage != SaleStage.NotStarted, "Sale has not started");
        require(currentStage != SaleStage.EndSale, "Sale has ended");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Not admin");
        _;
    }

    modifier onlyAfterSale() {
        require(currentStage == SaleStage.EndSale, "Sale has not ended");
        _;
    }

    /**
     * @dev Constructor to initialize the TokenSale contract with sale details.
     * @param _token ERC-20 token address.
     * @param _preSalePrice Token price during the presale.
     * @param _publicSalePrice Token price during the public sale.
     * @param _preSaleMinSalesCap Minimum Ether required for a successful presale.
     * @param _publicSaleMinSalesCap Minimum Ether required for a successful public sale.
     * @param _preSaleMaxSalesCap Maximum Ether that can be raised during the presale.
     * @param _publicSaleMaxSalesCap Maximum Ether that can be raised during the public sale.
     * @param _preSaleMinContribution Minimum contribution amount per participant during the presale.
     * @param _publicSaleMinContribution Minimum contribution amount per participant during the public sale.
     * @param _preSaleMaxContribution Maximum contribution amount per participant during the presale.
     * @param _publicSaleMaxContribution Maximum contribution amount per participant during the public sale.
     */
    constructor(
        IERC20 _token,
        uint256 _preSalePrice,
        uint256 _publicSalePrice,
        uint256 _preSaleMinSalesCap,
        uint256 _publicSaleMinSalesCap,
        uint256 _preSaleMaxSalesCap,
        uint256 _publicSaleMaxSalesCap,
        uint256 _preSaleMinContribution,
        uint256 _publicSaleMinContribution,
        uint256 _preSaleMaxContribution,
        uint256 _publicSaleMaxContribution
    ) Ownable(msg.sender) {
        // Validation checks for input parameters
        require(_preSalePrice > 0, "Pre Sale Price must be greater than zero");
        require(_publicSalePrice > 0, "Public Sale Price must be greater than zero");
        require(_preSaleMaxSalesCap > 0, "Pre Sale max cap must be greater than zero");
        require(_publicSaleMaxSalesCap > 0, "Public Sale max cap must be greater than zero");
        require(_preSaleMinSalesCap > 0, "Pre Sale min cap must be greater than zero");
        require(_publicSaleMinSalesCap > 0, "Public Sale min cap must be greater than zero");
        require(_preSaleMinSalesCap < _preSaleMaxSalesCap, "Pre Sale min cap must be less than Pre Sale max cap");
        require(_publicSaleMinSalesCap < _publicSaleMaxSalesCap, "Public Sale min cap must be less than Public Sale max cap");
        require(_preSaleMinContribution > 0, "Pre Sale Min contribution must be greater than zero");
        require(_publicSaleMinContribution > 0, "Public Sale Min contribution must be greater than zero");
        require(_preSaleMaxContribution >= _preSaleMinContribution, "Pre Sale Max contribution must be greater than or equal to Pre Sale Min contribution");
        require(_publicSaleMaxContribution >= _publicSaleMinContribution, "Public Sale Max contribution must be greater than or equal to Public Sale Min contribution");

        // Initializing the contract state
        token = _token;
        saleDetails[keccak256("PRE_SALE")] = Sale({
            price: _preSalePrice,
            maxSalesCap: _preSaleMaxSalesCap,
            minSalesCap: _preSaleMinSalesCap,
            totalSales: 0,
            minContribution: _preSaleMinContribution,
            maxContribution: _preSaleMaxContribution
        });
        saleDetails[keccak256("PUBLIC_SALE")] = Sale({
            price: _publicSalePrice,
            maxSalesCap: _publicSaleMaxSalesCap,
            minSalesCap: _publicSaleMinSalesCap,
            totalSales: 0,
            minContribution: _publicSaleMinContribution,
            maxContribution: _publicSaleMaxContribution
        });
    }

    /**
     * @dev Function to handle the purchase of tokens by contributors.
     */
    function buyTokens() external payable onlyWhileSaleOpen {
        if (currentStage == SaleStage.PreSale) {
            // Validation checks for presale contributions
            require(saleContributions[msg.sender][keccak256("PRE_SALE")] + msg.value >= saleDetails[keccak256("PRE_SALE")].minContribution, "Below min contribution");
            require(saleContributions[msg.sender][keccak256("PRE_SALE")] + msg.value <= saleDetails[keccak256("PRE_SALE")].maxContribution, "Exceeds max contribution");
            require(msg.value % saleDetails[keccak256("PRE_SALE")].price == 0, "Invalid contribution amount. Ensure msg.value is a multiple of the price");

            // Calculate tokens to be purchased and perform necessary validations
            uint256 tokensToPurchase = msg.value / saleDetails[keccak256("PRE_SALE")].price;
            require(saleDetails[keccak256("PRE_SALE")].totalSales + tokensToPurchase <= saleDetails[keccak256("PRE_SALE")].maxSalesCap, "Exceeds max sales cap");
            require(token.balanceOf(address(this)) >= tokensToPurchase, "Not enough tokens left for sale");

            // Transfer tokens to the buyer and update sale-related data
            token.transfer(msg.sender, tokensToPurchase);
            saleContributions[msg.sender][keccak256("PRE_SALE")] += msg.value;
            saleDetails[keccak256("PRE_SALE")].totalSales += tokensToPurchase;

            // Emit TokenPurchase event
            emit TokenPurchase(msg.sender, msg.value, tokensToPurchase, currentStage);
        } else {
            // Validation checks for public sale contributions
            require(saleContributions[msg.sender][keccak256("PUBLIC_SALE")] + msg.value >= saleDetails[keccak256("PUBLIC_SALE")].minContribution, "Below min contribution");
            require(saleContributions[msg.sender][keccak256("PUBLIC_SALE")] + msg.value <= saleDetails[keccak256("PUBLIC_SALE")].maxContribution, "Exceeds max contribution");
            require(msg.value % saleDetails[keccak256("PUBLIC_SALE")].price == 0, "Invalid contribution amount. Ensure msg.value is a multiple of the price");

            // Calculate tokens to be purchased and perform necessary validations
            uint256 tokensToPurchase = msg.value / saleDetails[keccak256("PUBLIC_SALE")].price;
            require(saleDetails[keccak256("PUBLIC_SALE")].totalSales + tokensToPurchase <= saleDetails[keccak256("PUBLIC_SALE")].maxSalesCap, "Exceeds max sales cap");
            require(token.balanceOf(address(this)) >= tokensToPurchase, "Not enough tokens left for sale");

            // Transfer tokens to the buyer and update sale-related data
            token.transfer(msg.sender, tokensToPurchase);
            saleContributions[msg.sender][keccak256("PUBLIC_SALE")] += msg.value;
            saleDetails[keccak256("PUBLIC_SALE")].totalSales += tokensToPurchase;

            // Emit TokenPurchase event
            emit TokenPurchase(msg.sender, msg.value, tokensToPurchase, currentStage);
        }
    }

    /**
     * @dev Function to transition the sale to the next stage. Only callable by the owner.
     */
    function transitionToNextStage() external onlyOwner {
        require(currentStage != SaleStage.EndSale, "Sale has already ended");

        if (currentStage == SaleStage.NotStarted) {
            // Ensure enough tokens are available to start the presale
            require(token.balanceOf(address(this)) >= saleDetails[keccak256("PRE_SALE")].maxSalesCap, "Not enough tokens to start pre-sale");
            currentStage = SaleStage.PreSale;
        } else if (currentStage == SaleStage.PreSale) {
            // Ensure enough tokens are available to start the public sale
            require(token.balanceOf(address(this)) >= saleDetails[keccak256("PUBLIC_SALE")].maxSalesCap, "Not enough tokens to start public-sale");
            currentStage = SaleStage.PublicSale;
        } else if (currentStage == SaleStage.PublicSale) {
            // Transition to the EndSale stage
            currentStage = SaleStage.EndSale;
        }

        // Emit StageChanged event
        emit StageChanged(currentStage);
    }

    /**
     * @dev Function to withdraw excess tokens after the sale has ended. Only callable by the owner.
     */
    function withdrawExcessTokens() external onlyAdmin onlyAfterSale {
        uint256 excessTokens = token.balanceOf(address(this));
        if (excessTokens > 0) {
            token.transfer(owner(), excessTokens);
        }
    }

    /**
     * @dev Function to withdraw Ether from the contract after the sale has ended. Only callable by the owner.
     * @param amount Amount of Ether to withdraw.
     */
    function withdrawEth(uint256 amount) external onlyAdmin {
        require(currentStage == SaleStage.PublicSale || currentStage == SaleStage.EndSale, "Cannot withdraw ether before pre-sale has ended");

        uint256 availableEther;

        if (currentStage == SaleStage.PublicSale) {
            // Ensure the presale minimum sale cap is reached
            require(saleDetails[keccak256("PRE_SALE")].totalSales >= saleDetails[keccak256("PRE_SALE")].minSalesCap, "Pre-sale minimum sale cap not reached");

            // Calculate available Ether for withdrawal
            availableEther = address(this).balance - (saleDetails[keccak256("PUBLIC_SALE")].totalSales * saleDetails[keccak256("PUBLIC_SALE")].price);
        } else {
            // Ensure the minimum sale cap for either the presale or public sale is reached
            require((saleDetails[keccak256("PUBLIC_SALE")].totalSales >= saleDetails[keccak256("PUBLIC_SALE")].minSalesCap) || (saleDetails[keccak256("PRE_SALE")].totalSales >= saleDetails[keccak256("PRE_SALE")].minSalesCap), "Minimum sale cap not reached");

            if (saleDetails[keccak256("PUBLIC_SALE")].totalSales >= saleDetails[keccak256("PUBLIC_SALE")].minSalesCap && saleDetails[keccak256("PRE_SALE")].totalSales >= saleDetails[keccak256("PRE_SALE")].minSalesCap) {
                // Calculate available Ether for withdrawal
                availableEther = address(this).balance;
            } else {
                // Calculate available Ether for withdrawal based on the stage with a successful sale
                if (saleDetails[keccak256("PUBLIC_SALE")].totalSales >= saleDetails[keccak256("PUBLIC_SALE")].minSalesCap) {
                    availableEther = address(this).balance - (saleDetails[keccak256("PRE_SALE")].totalSales * saleDetails[keccak256("PRE_SALE")].price);
                }
                if (saleDetails[keccak256("PRE_SALE")].totalSales >= saleDetails[keccak256("PRE_SALE")].minSalesCap) {
                    availableEther = address(this).balance - (saleDetails[keccak256("PUBLIC_SALE")].totalSales * saleDetails[keccak256("PUBLIC_SALE")].price);
                }
            }
        }

        // Ensure requested withdrawal amount does not exceed available Ether
        require(amount <= availableEther, "Not enough ether");

        // Transfer Ether to the owner
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Ether transfer failed");
    }

    /**
     * @dev Function to add tokens to the sale. Only callable by the owner.
     * @param _amount Amount of tokens to add.
     */
    function addTokens(uint256 _amount) external onlyAdmin {
        // Transfer tokens from the owner to the contract
        token.transferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @dev Function to claim a refund after the sale has ended. Only callable by participants and if the sale failed to meet the minimum sales cap.
     */
    function claimRefund() external {
        // Ensure at least presale is over
        require(
            currentStage == SaleStage.EndSale ||
                currentStage == SaleStage.PublicSale,
            "Can't claim refund yet"
        );

        // Ensure the sale failed to meet the minimum sales cap
        require(
            saleContributions[msg.sender][PRE_SALE] > 0 ||
                saleContributions[msg.sender][PUBLIC_SALE] > 0,
            "No contribution"
        );
        uint256 availableRefundAmount = 0;
        uint256 tokensToClaim = 0;
        if (
            saleDetails[PRE_SALE].totalSales < saleDetails[PRE_SALE].minSalesCap
        ) {
            // If the presale failed to meet the minimum sales cap, refund the entire presale contribution
            availableRefundAmount +=
                saleContributions[msg.sender][PRE_SALE] ;
            tokensToClaim +=
                saleContributions[msg.sender][PRE_SALE] /
                saleDetails[PRE_SALE].price;
        }
        if (
            saleDetails[PUBLIC_SALE].totalSales <
            saleDetails[PUBLIC_SALE].minSalesCap
        ) {
            // If the public sale failed to meet the minimum sales cap and has ended, refund the entire public sale contribution
            if (currentStage == SaleStage.EndSale) {
                availableRefundAmount +=
                    saleContributions[msg.sender][PUBLIC_SALE] ;
                tokensToClaim +=
                    saleContributions[msg.sender][PUBLIC_SALE] /
                    saleDetails[PUBLIC_SALE].price;
            }
        }
        require(availableRefundAmount > 0, "No refund available. All sales met min cap or sale has not ended");

        // Ensure the user has approved the contract to transfer back the tokens
        require(
            token.allowance(msg.sender, address(this)) >= tokensToClaim,
            "Approve tokenSale to transfer tokens back"
        );
        token.transferFrom(msg.sender, address(this), tokensToClaim);
        (bool success, ) = payable(msg.sender).call{
            value: availableRefundAmount
        }("");
        require(success, "Ether transfer failed");
        saleContributions[msg.sender][PRE_SALE] = 0;
        saleContributions[msg.sender][PUBLIC_SALE] = 0;
    }
    
    /**
     * @dev Function to get the total contribution of a user in each stage.
     * @param _user Address of the user.
     * @return Total contribution of the user in the presale.
     */
    function getContribution(
        address _user
    ) external view returns (uint256, uint256) {
        return (
            saleContributions[_user][PRE_SALE],
            saleContributions[_user][PUBLIC_SALE]
        );
    }
    
    /**
     * @dev Function to get the current price of the token.
     * @return price Current price of the token.
     */
    function getCurrentPrice() external view returns (uint256 price) {
        if (currentStage == SaleStage.PreSale) {
            return saleDetails[PRE_SALE].price;
        } else if (currentStage == SaleStage.PublicSale) {
            return saleDetails[PUBLIC_SALE].price;
        } else {
            return 0;
        }
    }
}
