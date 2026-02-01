//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MovieRights} from "src/MovieRights.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscriptionCode, FundSubscriptionCode, AddConsumer} from "./Interactions.s.sol";

contract DeployMovieRights is Script {
    HelperConfig helperConfig;
    MovieRights movieRights;

    function run() public returns (MovieRights) {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        if (config.subscriptionId == 0) {
            CreateSubscriptionCode createSubscription = new CreateSubscriptionCode();
            config.subscriptionId = createSubscription.getOrCreateSubscription(config.VrfCoordinator);
            FundSubscriptionCode fundSubscription = new FundSubscriptionCode();
            fundSubscription.fundingSubscription(config.VrfCoordinator, config.subscriptionId, config.linkToken);
        }
        vm.startBroadcast();
        movieRights = new MovieRights(
            config.priceFeed, config.VrfCoordinator, config.keyHash, config.subscriptionId, config.callBackLimit
        );
        vm.stopBroadcast();
        AddConsumer addingConsumerToContract = new AddConsumer();
        addingConsumerToContract.addConsumer(config.VrfCoordinator, address(movieRights), config.subscriptionId);
        return movieRights;
    }
}
