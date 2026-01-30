//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, ConfigConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscriptionCode is Script, ConfigConstants {
    function run() public {
        createSunscriptionFromConfig();
    }

    function createSunscriptionFromConfig() public returns (address, uint256) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        uint256 subId = getOrCreateSubscription(config.VrfCoordinator);
        return (config.VrfCoordinator, subId);
    }

    function getOrCreateSubscription(
        address _vrfCoordinator
    ) public returns (uint256) {
        uint256 subId;
        // if (block.chainid == LOCAL_ID) {
        vm.startBroadcast();
        subId = VRFCoordinatorV2_5Mock(_vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        // }
        return subId;
    }
}
