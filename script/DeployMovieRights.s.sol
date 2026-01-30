//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MovieRights} from "src/MovieRights.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscriptionCode} from "./Interactions.s.sol";

contract DeployMovieRights is Script {
    HelperConfig helperConfig;
    MovieRights movieRights;

    function run() public returns (MovieRights) {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        if (config.subscriptionId == 0) {
            CreateSubscriptionCode createSubscription = new CreateSubscriptionCode();
            config.subscriptionId = createSubscription.getOrCreateSubscription(
                config.VrfCoordinator
            );
        }
        vm.startBroadcast();
        movieRights = new MovieRights(
            config.priceFeed,
            config.VrfCoordinator,
            config.keyHash,
            config.subscriptionId,
            config.callBackLimit
        );
        vm.stopBroadcast();
        return movieRights;
    }
}
