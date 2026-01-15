//SPDX-License-Identifier:MIT

pragma solidity 0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {MovieRights} from "../../src/MovieRights.sol";

contract MovieRightsTest is Test {
    MovieRights public movieRights;
    address USER = makeAddr("user");

    function setUp() public {
        vm.startBroadcast(USER);
        movieRights = new MovieRights();
        vm.stopBroadcast();
    }

    function testOwner() public view {
        assert(movieRights.getOwner() == USER);
    }

    function testAuctionCreate() public {
        vm.prank(USER);
        movieRights.createAuction("Avengers", 100, 10, 20);
        assert(
            keccak256(abi.encodePacked(movieRights.getAuctionName())) ==
                keccak256(abi.encodePacked("Avengers"))
        );
    }
}
