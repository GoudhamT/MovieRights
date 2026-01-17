// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier:MIT

pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract MovieRights {
    /*Errors */
    error MovieRights__NotEnoughMoneyforAuction(uint256 _money);
    /* type declarations */
    enum AuctionStatus {
        OPEN,
        ASSIGNING,
        CLOSED
    }
    struct AuctionDetails {
        string movieName;
        uint256 minPriceInUSD;
        uint256 auctionDuration; // in seconds
        uint256 rightsDuration; // in seconds
        address[] highestBiders;
        address[] bidders;
        uint256 highestBidAmount;
        AuctionStatus auctionStatus;
    }

    /*state variables */
    AuctionDetails private s_auctionDetails;
    address private s_owner;
    AggregatorV3Interface public s_priceFeed;

    /*Events */
    event MovieRights__auctionCreated(
        string indexed movieName,
        uint256 minPrice
    );
    event MovieRights__PlacedBid(
        string indexed movieName,
        address indexed bidder,
        uint256 amount
    );

    constructor(address _feedAddress) {
        s_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_feedAddress);
    }

    /*Modifiers */
    modifier OwnerCannotBid() {
        require(msg.sender != s_owner, "You cannot bid");
        _;
    }

    function _getEthPriceInUSD() internal view returns (uint256) {
        uint256 minPrice = (s_auctionDetails.minPriceInUSD) * 1e18;
        uint256 EthInUSD = _getPrice();
        uint256 calculatedETH = (minPrice * 1e8) / EthInUSD;
        return calculatedETH;
    }

    function _getPrice() internal view returns (uint256) {
        (, int256 price, , , ) = s_priceFeed.latestRoundData();
        return uint256(price);
    }

    /*Functions */
    function createAuction(
        string memory _name,
        uint256 _minPrice,
        uint256 _auctionDuration,
        uint256 _rightsDuration
    ) public {
        AuctionDetails storage auction = s_auctionDetails;
        auction.movieName = _name;
        auction.minPriceInUSD = _minPrice;
        auction.auctionDuration = _auctionDuration;
        auction.rightsDuration = _rightsDuration;
        auction.auctionStatus = AuctionStatus.OPEN;

        emit MovieRights__auctionCreated(_name, _minPrice);
    }

    function enterBid() public payable {
        require(
            s_auctionDetails.auctionStatus == AuctionStatus.OPEN,
            "Auction is not Open"
        );

        if (msg.value < _getEthPriceInUSD()) {
            revert MovieRights__NotEnoughMoneyforAuction(msg.value);
        }
        /*Push Bidder */
        s_auctionDetails.bidders.push(msg.sender);
        if (msg.value >= getHighestAmount()) {
            s_auctionDetails.highestBidAmount = msg.value;
            s_auctionDetails.highestBiders.push(msg.sender);
        }
        emit MovieRights__PlacedBid(
            s_auctionDetails.movieName,
            msg.sender,
            msg.value
        );
    }

    /*view & pure functions */
    function getOwner() external view returns (address) {
        return s_owner;
    }

    function getAuction() external view returns (AuctionDetails memory) {
        return s_auctionDetails;
    }

    function getAuctionName() external view returns (string memory) {
        return s_auctionDetails.movieName;
    }

    function getHighestAmount() public view returns (uint256) {
        return s_auctionDetails.highestBidAmount;
    }
}
