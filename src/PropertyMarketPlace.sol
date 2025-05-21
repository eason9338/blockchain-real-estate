// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PropertyMarketplace {
    struct Listing {
        address seller;
        address tokenAddress;
        uint256 amount;
        uint256 pricePerToken; // 以 wei 計價
        bool active;
    }

    uint256 public nextListingId;
    mapping(uint256 => Listing) public listings;
    
    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        address indexed tokenAddress,
        uint256 amount,
        uint256 pricePerToken
    );
    
    event TokensPurchased(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 amount,
        uint256 totalPrice
    );
    
    event ListingCancelled(uint256 indexed listingId);
 
    // 創建賣單
    function createListing(
        address _tokenAddress,
        uint256 _amount,
        uint256 _pricePerToken
    ) external returns (uint256) {
        require(_amount > 0, "Amount must be greater than 0");
        require(_pricePerToken > 0, "Price must be greater than 0");
        
        // 確認賣家有足夠的代幣
        IERC20 token = IERC20(_tokenAddress);
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Insufficient balance"
        );
        
        // 確認賣家授權了足夠的代幣給市場合約
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Insufficient allowance"
        );
        
        uint256 listingId = nextListingId++;
        listings[listingId] = Listing({
            seller: msg.sender,
            tokenAddress: _tokenAddress,
            amount: _amount,
            pricePerToken: _pricePerToken,
            active: true
        });
        
        emit ListingCreated(
            listingId,
            msg.sender,
            _tokenAddress,
            _amount,
            _pricePerToken
        );
        
        return listingId;
    }

    // 購買代幣
    function purchaseTokens(uint256 _listingId, uint256 _amount) external payable {
        Listing storage listing = listings[_listingId];
        require(listing.active, "Listing is not active");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= listing.amount, "Not enough tokens available");
        
        uint256 totalPrice = _amount * listing.pricePerToken;
        require(msg.value >= totalPrice, "Insufficient payment");
        
        // 更新賣單數量
        listing.amount -= _amount;
        if (listing.amount == 0) {
            listing.active = false;
        }
        
        // 轉移代幣從賣家到買家
        IERC20 token = IERC20(listing.tokenAddress);
        require(
            token.transferFrom(listing.seller, msg.sender, _amount),
            "Token transfer failed"
        );
        
        // 轉移 ETH 給賣家
        payable(listing.seller).transfer(totalPrice);
        
        // 如果有多餘的 ETH，退還給買家
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
        
        emit TokensPurchased(_listingId, msg.sender, _amount, totalPrice);
    }

    // 取消賣單
    function cancelListing(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only seller can cancel");
        require(listing.active, "Listing is not active");
        
        listing.active = false;
        
        emit ListingCancelled(_listingId);
    }

    // 獲取所有活躍的賣單
    function getActiveListings() external view returns (
        uint256[] memory listingIds,
        address[] memory sellers,
        address[] memory tokenAddresses,
        uint256[] memory amounts,
        uint256[] memory prices
    ) {
        // 先計算活躍賣單數量
        uint256 activeCount = 0;
        for (uint256 i = 0; i < nextListingId; i++) {
            if (listings[i].active) {
                activeCount++;
            }
        }
        
        // 創建數組
        listingIds = new uint256[](activeCount);
        sellers = new address[](activeCount);
        tokenAddresses = new address[](activeCount);
        amounts = new uint256[](activeCount);
        prices = new uint256[](activeCount);
        
        // 填充數組
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < nextListingId; i++) {
            if (listings[i].active) {
                listingIds[currentIndex] = i;
                sellers[currentIndex] = listings[i].seller;
                tokenAddresses[currentIndex] = listings[i].tokenAddress;
                amounts[currentIndex] = listings[i].amount;
                prices[currentIndex] = listings[i].pricePerToken;
                currentIndex++;
            }
        }
        
        return (listingIds, sellers, tokenAddresses, amounts, prices);
    }
}