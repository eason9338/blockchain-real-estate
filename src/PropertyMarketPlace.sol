// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PropertyMarketplace {
    struct Listing {
        address seller;
        address tokenAddress;
        uint256 amount;
        uint256 pricePerToken;
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

    function createListing(
        address _tokenAddress,
        uint256 _amount,
        uint256 _pricePerToken
    ) external returns (uint256) {
        require(_tokenAddress != address(0), "createListing: token address is zero");
        require(_amount > 0, "createListing: amount must be greater than 0");
        require(_pricePerToken > 0, "createListing: price must be greater than 0");

        IERC20 token = IERC20(_tokenAddress);

        uint256 balance = token.balanceOf(msg.sender);

        // 要求持有的代幣量要大於要賣的代幣量
        require(balance >= _amount, "createListing: insufficient balance");

        uint256 allowance = token.allowance(msg.sender, address(this));

        // 要求授權的代幣量要大於要賣的代幣量
        require(allowance >= _amount, "createListing: insufficient allowance");

        uint256 listingId = nextListingId++;
        listings[listingId] = Listing({
            seller: msg.sender,
            tokenAddress: _tokenAddress,
            amount: _amount,
            pricePerToken: _pricePerToken,
            active: true
        });

        emit ListingCreated(listingId, msg.sender, _tokenAddress, _amount, _pricePerToken);
        return listingId;
    }

    function purchaseTokens(uint256 _listingId, uint256 _amount) external payable {
        require(_amount > 0, "purchaseTokens: amount must be greater than 0");
        require(_listingId < nextListingId, "purchaseTokens: invalid listingId");

        Listing storage listing = listings[_listingId];
        require(listing.active, "purchaseTokens: listing is not active");
        require(_amount <= listing.amount, "purchaseTokens: not enough tokens available");

        uint256 totalPrice = (_amount * listing.pricePerToken) / (10**18);
        require(msg.value >= totalPrice, "purchaseTokens: insufficient ETH sent");

        listing.amount -= _amount;
        if (listing.amount == 0) {
            listing.active = false;
        }

        IERC20 token = IERC20(listing.tokenAddress);
        require(
            token.transferFrom(listing.seller, msg.sender, _amount),
            "purchaseTokens: token transfer failed"
        );

        payable(listing.seller).transfer(totalPrice);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit TokensPurchased(_listingId, msg.sender, _amount, totalPrice);
    }

    function cancelListing(uint256 _listingId) external {
        require(_listingId < nextListingId, "cancelListing: invalid listingId");
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "cancelListing: only seller can cancel");
        require(listing.active, "cancelListing: listing is not active");

        listing.active = false;
        emit ListingCancelled(_listingId);
    }

    function getActiveListings()
        external
        view
        returns (
            uint256[] memory listingIds,
            address[] memory sellers,
            address[] memory tokenAddresses,
            uint256[] memory amounts,
            uint256[] memory prices
        )
    {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < nextListingId; i++) {
            if (listings[i].active) {
                activeCount++;
            }
        }

        listingIds = new uint256[](activeCount);
        sellers = new address[](activeCount);
        tokenAddresses = new address[](activeCount);
        amounts = new uint256[](activeCount);
        prices = new uint256[](activeCount);

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
