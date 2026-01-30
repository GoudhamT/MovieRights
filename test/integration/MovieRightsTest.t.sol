//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;
import {Test} from "forge-std/Test.sol";
import {DeployMovieRights} from "../../script/DeployMovieRights.s.sol";
// import {HelperConfig} from "script/HelperConfig.s.sol";
import {MovieRights} from "src/MovieRights.sol";

contract MovieRightsTest is Test {
    DeployMovieRights deployer;
    MovieRights movieRights;
    address USER = makeAddr("user");
    uint256 constant USER_BALANCE = 1000 ether;

    event MovieRights__auctionCreated(
        string indexed movieName,
        uint256 minPrice
    );

    event MovieRights__PlacedBid(
        string indexed movieName,
        address indexed bidder,
        uint256 amount
    );

    function setUp() public {
        deployer = new DeployMovieRights();
        movieRights = deployer.run();
    }

    /*//////////////////////////////////////////////////////////////
                              Create Auction
    //////////////////////////////////////////////////////////////*/
    function testCreateBidName() public {
        //Arrange
        string memory auctionName = "Duet";
        uint256 auctionPrice = 100;
        uint256 auctionDuration = 500;
        uint256 rightsDuration = 1500;
        //Act
        vm.prank(USER);
        movieRights.createAuction(
            auctionName,
            auctionPrice,
            auctionDuration,
            rightsDuration
        );
        //Assert
        assert(
            keccak256(abi.encode(auctionName)) ==
                keccak256(abi.encode(movieRights.getAuctionName()))
        );
    }

    function testAuctionAmountZero() public {
        //Arrange
        string memory auctionName = "Duet";
        uint256 auctionPrice = 0;
        uint256 auctionDuration = 500;
        uint256 rightsDuration = 1500;
        //Act
        vm.prank(USER);
        vm.expectRevert(
            abi.encodeWithSelector(
                MovieRights.MovieRights__InvalidRightsAmount.selector,
                auctionPrice
            )
        );
        movieRights.createAuction(
            auctionName,
            auctionPrice,
            auctionDuration,
            rightsDuration
        );
    }

    function testAuctionAndRightsDuration() public {
        //Arrange
        string memory auctionName = "Duet";
        uint256 auctionPrice = 100;
        uint256 auctionDuration = 0;
        uint256 rightsDuration = 0;
        //Act / //Assert
        vm.prank(USER);
        vm.expectRevert();
        movieRights.createAuction(
            auctionName,
            auctionPrice,
            auctionDuration,
            rightsDuration
        );
    }

    function testCreateAuction() public {
        //Arrange
        string memory auctionName = "Duet";
        uint256 auctionPrice = 100;
        uint256 auctionDuration = 500;
        uint256 rightsDuration = 1500;
        //Act & assert
        vm.prank(USER);
        movieRights.createAuction(
            auctionName,
            auctionPrice,
            auctionDuration,
            rightsDuration
        );
    }

    function testCreateAuctionCheckStatusOpen() public {
        //Arrange
        string memory auctionName = "Duet";
        uint256 auctionPrice = 100;
        uint256 auctionDuration = 500;
        uint256 rightsDuration = 1500;
        //Act
        vm.prank(USER);
        movieRights.createAuction(
            auctionName,
            auctionPrice,
            auctionDuration,
            rightsDuration
        );
        //Assert
        assert(
            movieRights.getAuctionStatus() == MovieRights.AuctionStatus.OPEN
        );
    }

    function testCreateAuctionCheckEvent() public {
        //Arrange
        string memory auctionName = "Duet";
        uint256 auctionPrice = 100;
        uint256 auctionDuration = 500;
        uint256 rightsDuration = 1500;
        //Act / //Assert
        vm.prank(USER);
        vm.expectEmit(true, false, false, true, address(movieRights));
        emit MovieRights__auctionCreated(auctionName, auctionPrice);
        movieRights.createAuction(
            auctionName,
            auctionPrice,
            auctionDuration,
            rightsDuration
        );
    }

    /*//////////////////////////////////////////////////////////////
                              Bid Auction
    //////////////////////////////////////////////////////////////*/
    function testBidErrorforAuctionAmount() public {
        //Arrange
        vm.prank(USER);
        //Act / //Assert
        vm.expectRevert(
            MovieRights.MovieRights__AuctionPricecannotBeZero.selector
        );
        movieRights.enterBid{value: 0}();
    }

    function testAuctionAndBidNoValue() public {
        //Arrange
        string memory auctionName = "Duet";
        uint256 auctionPrice = 100;
        uint256 auctionDuration = 500;
        uint256 rightsDuration = 1500;
        //Act
        vm.prank(USER);
        movieRights.createAuction(
            auctionName,
            auctionPrice,
            auctionDuration,
            rightsDuration
        );
        vm.prank(USER);
        vm.expectRevert(
            abi.encodeWithSelector(
                MovieRights.MovieRights__NotEnoughMoneyforAuction.selector,
                0
            )
        );
        movieRights.enterBid{value: 0}();
    }

    function testAuctionandBidInfo() public {
        //Arrange
        string memory auctionName = "Duet";
        uint256 auctionPrice = 100;
        uint256 auctionDuration = 500;
        uint256 rightsDuration = 1500;
        //Act
        vm.prank(USER);
        movieRights.createAuction(
            auctionName,
            auctionPrice,
            auctionDuration,
            rightsDuration
        );
        vm.prank(USER);
        vm.deal(USER, USER_BALANCE);
        movieRights.enterBid{value: 5 ether}();
        //Assert
        assert(movieRights.getAuction().bidders.length == 1);
        assert(movieRights.getHighestAmount() == 5 ether);
    }

    function testAuctionandBidEvent() public {
        //Arrange
        string memory auctionName = "Duet";
        uint256 auctionPrice = 100;
        uint256 auctionDuration = 500;
        uint256 rightsDuration = 1500;
        //Act / Assert
        vm.prank(USER);
        movieRights.createAuction(
            auctionName,
            auctionPrice,
            auctionDuration,
            rightsDuration
        );

        vm.deal(USER, USER_BALANCE);
        vm.expectEmit(true, true, false, true, address(movieRights));
        vm.prank(USER);
        emit MovieRights__PlacedBid(auctionName, USER, 5 ether);
        movieRights.enterBid{value: 5 ether}();
    }
}
