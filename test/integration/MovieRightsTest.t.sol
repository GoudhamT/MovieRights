//SPDX-License-Identifier:MIT

pragma solidity 0.8.19;
import {Test} from "forge-std/Test.sol";
import {DeployMovieRights} from "../../script/DeployMovieRights.s.sol";
// import {HelperConfig} from "script/HelperConfig.s.sol";
import {MovieRights} from "src/MovieRights.sol";

contract MovieRightsTest is Test {
    DeployMovieRights deployer;
    MovieRights movieRights;
    address USER = makeAddr("user");

    event MovieRights__auctionCreated(
        string indexed movieName,
        uint256 minPrice
    );

    function setUp() public {
        deployer = new DeployMovieRights();
        movieRights = deployer.run();
    }

    /*//////////////////////////////////////////////////////////////
                              Create Auction
    //////////////////////////////////////////////////////////////*/

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
        //Act
        vm.prank(USER);
        vm.expectEmit(true, false, false, true, address(movieRights));
        emit MovieRights__auctionCreated(auctionName, auctionPrice);
        movieRights.createAuction(
            auctionName,
            auctionPrice,
            auctionDuration,
            rightsDuration
        );
        //Assert
    }
}
