//SPDX-License-Identifier:MIT

pragma solidity 0.8.19;
import {Test} from "forge-std/Test.sol";
import {DeployMovieRights} from "../../script/DeployMovieRights.s.sol";
// import {HelperConfig} from "script/HelperConfig.s.sol";
import {MovieRights} from "src/MovieRights.sol";

contract MovieRightsTest is Test {
    DeployMovieRights deployer;
    MovieRights movieRights;

    function setUp() public {
        deployer = new DeployMovieRights();
        movieRights = deployer.run();
        // HelperConfig.NetworkConfig memory config = deployer.run();
    }

    function testPrice() public view {
        assert(movieRights.getPrice() == 2e11);
    }
}
