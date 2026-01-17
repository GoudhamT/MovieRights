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
    /* type declarations */
    struct AuctionDetails {
        string movieName;
        uint256 minPriceInUSD;
        uint256 auctionDuration; // in seconds
        uint256 rightsDuration; // in seconds
        address[] highestBiders;
        address[] bidders;
        uint256 highestBidAmount;
    }

    /*state variables */
    AuctionDetails private s_auctionDetails;
    address private s_owner;

    /*Events */
    event MovieRights__auctionCreated(
        string indexed movieName,
        uint256 minPrice
    );

    constructor() {
        s_owner = msg.sender;
    }

    /*Modifiers */
    modifier OwnerCannotBid() {
        require(msg.sender != s_owner, "You cannot bid");
        _;
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

        emit MovieRights__auctionCreated(_name, _minPrice);
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
}
