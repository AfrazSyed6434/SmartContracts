// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSale is Ownable {
    IERC20 public token;
    bytes32 public constant PRE_SALE = keccak256("PRE_SALE");
    bytes32 public constant PUBLIC_SALE = keccak256("PUBLIC_SALE");
    // uint256 public ethToTokenMultiplier;
    // uint256 public saleMaxCap;
    // uint256 public saleMinCap;
    // uint256 public saleTotal = 0;
    // uint256 public minContribution;
    // uint256 public maxContribution;
    SaleStage public currentStage = SaleStage.NotStarted;
    mapping(bytes32 => Sale) public saleDetails;
    mapping(address => mapping(bytes32 => uint256)) public saleContributions;

    enum SaleStage {
        NotStarted,
        PreSale,
        PublicSale,
        EndSale
    }

    struct Sale {
        uint256 price;
        uint256 maxSalesCap;
        uint256 minSalesCap;
        uint256 totalSales;
        uint256 minContribution;
        uint256 maxContribution;
    }

    event TokenPurchase(
        address indexed buyer,
        uint256 ethAmount,
        uint256 tokenAmount,
        SaleStage saleStage
    );
    event StageChanged(SaleStage newStage);

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
        require(_preSalePrice > 0, "Pre Sale Price must be greater than zero");
        require(
            _publicSalePrice > 0,
            "Public Sale Price must be greater than zero"
        );
        require(
            _preSaleMaxSalesCap > 0,
            "Pre Sale max cap must be greater than zero"
        );
        require(
            _publicSaleMaxSalesCap > 0,
            "Public Sale max cap must be greater than zero"
        );
        require(
            _preSaleMinSalesCap > 0,
            "Pre Sale min cap must be greater than zero"
        );
        require(
            _publicSaleMinSalesCap > 0,
            "Public Sale min cap must be greater than zero"
        );
        require(
            _preSaleMinSalesCap < _preSaleMaxSalesCap,
            "Pre Sale min cap must be less than Pre Sale max cap"
        );
        require(
            _publicSaleMinSalesCap < _publicSaleMaxSalesCap,
            "Public Sale min cap must be less than Public Sale max cap"
        );
        require(
            _preSaleMinContribution > 0,
            "Pre Sale Min contribution must be greater than zero"
        );
        require(
            _publicSaleMinContribution > 0,
            "Public Sale Min contribution must be greater than zero"
        );
        require(
            _preSaleMaxContribution >= _preSaleMinContribution,
            "Pre Sale Max contribution must be greater than or equal to Pre Sale Min contribution"
        );
        require(
            _publicSaleMaxContribution >= _publicSaleMinContribution,
            "Public Sale Max contribution must be greater than or equal to Public Sale Min contribution"
        );
        token = _token;
        saleDetails[PRE_SALE] = Sale({
            price: _preSalePrice,
            maxSalesCap: _preSaleMaxSalesCap,
            minSalesCap: _preSaleMinSalesCap,
            totalSales: 0,
            minContribution: _preSaleMinContribution,
            maxContribution: _preSaleMaxContribution
        });
        saleDetails[PUBLIC_SALE] = Sale({
            price: _publicSalePrice,
            maxSalesCap: _publicSaleMaxSalesCap,
            minSalesCap: _publicSaleMinSalesCap,
            totalSales: 0,
            minContribution: _publicSaleMinContribution,
            maxContribution: _publicSaleMaxContribution
        });
    }

    function buyTokens() external payable onlyWhileSaleOpen {
        // require(msg.value >= minContribution, "Below min contribution");
        // require(msg.value <= maxContribution, "Exceeds max contribution");
        if (currentStage == SaleStage.PreSale) {
            require(
                saleContributions[msg.sender][PRE_SALE] + msg.value >=
                    saleDetails[PRE_SALE].minContribution,
                "Below min contribution"
            );
            require(
                saleContributions[msg.sender][PRE_SALE] + msg.value <=
                    saleDetails[PRE_SALE].maxContribution,
                "Exceeds max contribution"
            );
            require(
                msg.value % saleDetails[PRE_SALE].price == 0,
                "Invalid contribution amount. Ensure msg.value is a multiple of the price"
            );
            uint256 tokensToPurchase = msg.value / saleDetails[PRE_SALE].price;
            require(
                saleDetails[PRE_SALE].totalSales + tokensToPurchase <=
                    saleDetails[PRE_SALE].maxSalesCap,
                "Exceeds max sales cap"
            );
            require(
                token.balanceOf(address(this)) >= tokensToPurchase,
                "Not enough tokens left for sale"
            );

            token.transfer(msg.sender, tokensToPurchase);
            saleContributions[msg.sender][PRE_SALE] += msg.value;
            saleDetails[PRE_SALE].totalSales += tokensToPurchase;

            emit TokenPurchase(
                msg.sender,
                msg.value,
                tokensToPurchase,
                currentStage
            );
        } else {
            require(
                saleContributions[msg.sender][PUBLIC_SALE] + msg.value >=
                    saleDetails[PUBLIC_SALE].minContribution,
                "Below min contribution"
            );
            require(
                saleContributions[msg.sender][PUBLIC_SALE] + msg.value <=
                    saleDetails[PUBLIC_SALE].maxContribution,
                "Exceeds max contribution"
            );
            require(
                msg.value % saleDetails[PUBLIC_SALE].price == 0,
                "Invalid contribution amount. Ensure msg.value is a multiple of the price"
            );
            uint256 tokensToPurchase = msg.value /
                saleDetails[PUBLIC_SALE].price;
            require(
                saleDetails[PUBLIC_SALE].totalSales + tokensToPurchase <=
                    saleDetails[PUBLIC_SALE].maxSalesCap,
                "Exceeds max sales cap"
            );
            require(
                token.balanceOf(address(this)) >= tokensToPurchase,
                "Not enough tokens left for sale"
            );

            token.transfer(msg.sender, tokensToPurchase);
            saleContributions[msg.sender][PUBLIC_SALE] += msg.value;
            saleDetails[PUBLIC_SALE].totalSales += tokensToPurchase;

            emit TokenPurchase(
                msg.sender,
                msg.value,
                tokensToPurchase,
                currentStage
            );
        }
    }

    function transitionToNextStage() external onlyOwner {
        require(currentStage != SaleStage.EndSale, "Sale has already ended");
        if (currentStage == SaleStage.NotStarted) {
            require(
                token.balanceOf(address(this)) >=
                    saleDetails[PRE_SALE].maxSalesCap,
                "Not enough tokens to start pre-sale"
            );
            currentStage = SaleStage.PreSale;
        } else if (currentStage == SaleStage.PreSale) {
            require(
                token.balanceOf(address(this)) >=
                    saleDetails[PUBLIC_SALE].maxSalesCap,
                "Not enough tokens to start public-sale"
            );
            currentStage = SaleStage.PublicSale;
        } else if (currentStage == SaleStage.PublicSale) {
            currentStage = SaleStage.EndSale;
        }
        emit StageChanged(currentStage);
    }

    // In case tokens are sent to this contract by mistake, the admin can withdraw them
    function withdrawExcessTokens() external onlyAdmin onlyAfterSale {
        uint256 excessTokens = token.balanceOf(address(this));
        if (excessTokens > 0) {
            token.transfer(owner(), excessTokens);
        }
    }

    // In case there is remaining ether in the contract, the admin can withdraw it after the sale has ended
    function withdrawEth(uint256 amount) external onlyAdmin {
        require(
            currentStage == SaleStage.PublicSale ||
                currentStage == SaleStage.EndSale,
            "Cannot withdraw ether before pre-sale has ended"
        );
        uint256 availableEther;
        if (currentStage == SaleStage.PublicSale) {
            require(
                saleDetails[PRE_SALE].totalSales >=
                    saleDetails[PRE_SALE].minSalesCap,
                "Pre-sale minimum sale cap not reached"
            );
            availableEther =
                address(this).balance -
                (saleDetails[PUBLIC_SALE].totalSales *
                    saleDetails[PUBLIC_SALE].price);
        } else {
            require(
                saleDetails[PUBLIC_SALE].totalSales >=
                    saleDetails[PUBLIC_SALE].minSalesCap ||
                    saleDetails[PRE_SALE].totalSales >=
                    saleDetails[PRE_SALE].minSalesCap,
                "Minimum sale cap not reached"
            );
            if (
                saleDetails[PUBLIC_SALE].totalSales >=
                saleDetails[PUBLIC_SALE].minSalesCap &&
                saleDetails[PRE_SALE].totalSales >=
                saleDetails[PRE_SALE].minSalesCap
            ) {
                availableEther = address(this).balance;
            } else {
                if (
                    saleDetails[PUBLIC_SALE].totalSales >=
                    saleDetails[PUBLIC_SALE].minSalesCap
                ) {
                    availableEther =
                        address(this).balance -
                        (saleDetails[PRE_SALE].totalSales *
                            saleDetails[PRE_SALE].price);
                }
                if (
                    saleDetails[PRE_SALE].totalSales >=
                    saleDetails[PRE_SALE].minSalesCap
                ) {
                    availableEther =
                        address(this).balance -
                        (saleDetails[PUBLIC_SALE].totalSales *
                            saleDetails[PUBLIC_SALE].price);
                }
            }
        }
        require(amount <= availableEther, "Not enough ether");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Ether transfer failed");
    }

    function addTokens(uint256 _amount) external onlyAdmin {
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function claimRefund() external {
        require(
            currentStage == SaleStage.EndSale ||
                currentStage == SaleStage.PublicSale,
            "Can't claim refund yet"
        );
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
            if (currentStage == SaleStage.EndSale) {
                availableRefundAmount +=
                    saleContributions[msg.sender][PUBLIC_SALE] ;
                tokensToClaim +=
                    saleContributions[msg.sender][PUBLIC_SALE] /
                    saleDetails[PUBLIC_SALE].price;
            }
        }
        require(availableRefundAmount > 0, "No refund available. All sales met min cap or sale has not ended");
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

    function getContribution(
        address _user
    ) external view returns (uint256, uint256) {
        return (
            saleContributions[_user][PRE_SALE],
            saleContributions[_user][PUBLIC_SALE]
        );
    }

    function getCurrentPrice() external view returns (uint256) {
        if (currentStage == SaleStage.PreSale) {
            return saleDetails[PRE_SALE].price;
        } else if (currentStage == SaleStage.PublicSale) {
            return saleDetails[PUBLIC_SALE].price;
        } else {
            return 0;
        }
    }
}
