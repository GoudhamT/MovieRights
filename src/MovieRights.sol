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

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract MovieRights is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /*Errors */
    error MovieRights__NotEnoughMoneyforAuction(uint256 _money);
    error MovieRights__InvalidRightsAmount(uint256);
    error MovieRights__AuctionPricecannotBeZero();
    error MovieRights__CheckFailed(AuctionStatus, uint256, uint256);
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
        address creator;
    }

    /*state variables */
    AuctionDetails private s_auctionDetails;
    mapping(address => uint256) private s_bidderAmounts;
    address private s_owner;
    AggregatorV3Interface public s_priceFeed;
    address private s_VRFCoordinator;
    bytes32 private s_keyHash;
    uint256 private s_subscriptionId;
    uint16 constant REQUEST_CONFIRMATION = 3;
    uint32 private s_callBakLimit;
    uint32 constant NUM_WORDS = 1;

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
    event MovieRights__distributorSelected(address indexed winner);
    event MovieRights__RightsPaymentSuccessful();

    constructor(
        address _feedAddress,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _subId,
        uint32 _gasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        s_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_feedAddress);
        s_VRFCoordinator = _vrfCoordinator;
        s_keyHash = _keyHash;
        s_subscriptionId = _subId;
        s_callBakLimit = _gasLimit;
    }

    /*Modifiers */
    modifier OwnerCannotBid() {
        require(msg.sender != s_owner, "You cannot bid");
        _;
    }

    function _getMinEthRequired() internal view returns (uint256) {
        uint256 minPrice = (s_auctionDetails.minPriceInUSD) * 1e18;
        uint256 EthInUSD = getPrice();
        uint256 calculatedETH = (minPrice * 1e8) / EthInUSD;
        return calculatedETH;
    }

    function getPrice() internal view returns (uint256) {
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
        if (_minPrice <= 0) {
            revert MovieRights__InvalidRightsAmount(_minPrice);
        }
        require(_auctionDuration > 0, "Invalid auction duration");
        require(_rightsDuration > 0, "Invalid rights duration");
        AuctionDetails storage auction = s_auctionDetails;
        auction.movieName = _name;
        auction.minPriceInUSD = _minPrice;
        auction.auctionDuration = _auctionDuration;
        auction.rightsDuration = _rightsDuration;
        auction.auctionStatus = AuctionStatus.OPEN;
        auction.creator = msg.sender;

        emit MovieRights__auctionCreated(_name, _minPrice);
    }

    function enterBid() public payable {
        if (s_auctionDetails.minPriceInUSD <= 0) {
            revert MovieRights__AuctionPricecannotBeZero();
        }

        require(
            s_auctionDetails.auctionStatus == AuctionStatus.OPEN,
            "Auction is not Open"
        );

        if (msg.value < _getMinEthRequired()) {
            revert MovieRights__NotEnoughMoneyforAuction(msg.value);
        }
        /*Push Bidder */
        // s_auctionDetails.bidders.push(msg.sender);
        s_bidderAmounts[msg.sender] = msg.value;
        s_auctionDetails.bidders.push(msg.sender);
        if (msg.value > getHighestAmount()) {
            s_auctionDetails.highestBidAmount = msg.value;
            /**resetting higest bidder */
            s_auctionDetails.highestBiders = new address[](0);
            s_auctionDetails.highestBiders.push(msg.sender);
        } else if (msg.value == getHighestAmount()) {
            s_auctionDetails.highestBidAmount = msg.value;
            s_auctionDetails.highestBiders.push(msg.sender);
        }
        emit MovieRights__PlacedBid(
            s_auctionDetails.movieName,
            msg.sender,
            msg.value
        );
    }

    /*VRF functionality to chose distributor */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isAuctionOpen = s_auctionDetails.auctionStatus ==
            AuctionStatus.OPEN;
        bool isDuration = s_auctionDetails.auctionDuration > block.timestamp;
        bool isHighestBider = s_auctionDetails.highestBiders.length > 0;
        upkeepNeeded = isAuctionOpen && isDuration && isHighestBider;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool isAuctionOk, ) = checkUpkeep("");
        if (!isAuctionOk) {
            revert MovieRights__CheckFailed(
                s_auctionDetails.auctionStatus,
                block.timestamp,
                s_auctionDetails.highestBiders.length
            );
        }
        s_auctionDetails.auctionStatus = AuctionStatus.ASSIGNING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: s_callBakLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        uint256 noOfBiders = s_auctionDetails.highestBiders.length;
        uint256 winningNumber = randomWords[0] % noOfBiders;
        address distributor = s_auctionDetails.highestBiders[winningNumber];
        emit MovieRights__distributorSelected(distributor);
        uint256 amountToBeTransferred = s_bidderAmounts[distributor];
        (bool success, ) = payable(s_auctionDetails.creator).call{
            value: amountToBeTransferred
        }("");
        if (success) {
            emit MovieRights__RightsPaymentSuccessful();
        }
        s_auctionDetails.auctionStatus = AuctionStatus.CLOSED;
        s_auctionDetails.highestBidAmount = 0;
        s_auctionDetails.highestBiders = new address[](0);
        /*resetting bideers array in auctionDetails */
        for (uint256 i = 0; i <= s_auctionDetails.bidders.length; i++) {
            delete s_bidderAmounts[s_auctionDetails.bidders[i]];
        }
        s_auctionDetails.bidders = new address[](0);
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

    function getAuctionStatus() public view returns (AuctionStatus) {
        return s_auctionDetails.auctionStatus;
    }
}
