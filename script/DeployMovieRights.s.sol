//SPDX-License-Identifier:MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {MovieRights} from "src/MovieRights.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMovieRights is Script {
    HelperConfig helperConfig;
    MovieRights movieRights;

    function run() public returns (MovieRights) {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.startBroadcast();
        movieRights = new MovieRights(config.priceFeed);
        vm.stopBroadcast();
        return movieRights;
    }
}
