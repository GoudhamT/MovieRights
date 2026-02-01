//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, ConfigConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

interface LinkToken {
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);
}

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

    function getOrCreateSubscription(address _vrfCoordinator) public returns (uint256) {
        uint256 subId;
        // if (block.chainid == LOCAL_ID) {
        vm.startBroadcast();
        subId = VRFCoordinatorV2_5Mock(_vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        // }
        return subId;
    }
}

contract FundSubscriptionCode is Script, ConfigConstants {
    uint256 private constant FUNDING_AMOUNT = 3 ether;

    function run() public {
        fundSubscription();
    }

    function fundSubscription() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        fundingSubscription(config.VrfCoordinator, config.subscriptionId, config.linkToken);
    }

    function fundingSubscription(address _vrfCoordinator, uint256 _subId, address _link) public {
        if (block.chainid == LOCAL_ID) {
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(_subId, FUNDING_AMOUNT);
        } else {
            vm.startBroadcast();
            LinkToken(_link).transferAndCall(_vrfCoordinator, FUNDING_AMOUNT, abi.encode(_subId));
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
    function run() public {
        address recentDeployedContract = DevOpsTools.get_most_recent_deployment("MovieRights", block.chainid);
        addConsumerUsingConfig(recentDeployedContract);
    }

    function addConsumerUsingConfig(address _recentlyDeployedContract) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().VrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        addConsumer(vrfCoordinator, _recentlyDeployedContract, subId);
    }

    function addConsumer(address _vrfCoordinator, address _deployedConract, uint256 _subId) public {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(_vrfCoordinator).addConsumer(_subId, _deployedConract);
        vm.stopBroadcast();
    }
}
