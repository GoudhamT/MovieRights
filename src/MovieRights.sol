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

contract MovieRights {
    /**
     * @author: Goudham
     * @dev : contract uses chainlink data feed, VRF and NFT
     * @notice: contract created for movie rights auction
     */

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
}
