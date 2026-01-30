//SPDx-License-Identifier:MIT

pragma solidity ^0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract ConfigConstants {
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_ID = 31337;
    uint8 public constant MOCK_DECIMALS = 8;
    int256 public constant MOCK_ANSWER = 2000e8;
    uint96 public constant MOCK_BASE_FEE = 1e17;
    uint96 public constant MOCK_GAS_PRICE = 1e10;
    int256 public constant MOCK_WEI_LINK = 300;
}

contract HelperConfig is Script, ConfigConstants {
    struct NetworkConfig {
        address priceFeed;
        address VrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callBackLimit;
    }

    NetworkConfig public localNetworkConfig;

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigbyChain(block.chainid);
    }

    function getConfigbyChain(
        uint256 _chainId
    ) public returns (NetworkConfig memory) {
        if (_chainId == SEPOLIA_CHAIN_ID) {
            return getSepoliConfig();
        } else if (_chainId == LOCAL_ID) {
            return getLocalConfig();
        }
    }

    function getSepoliConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
                VrfCoordinator: 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE,
                keyHash: 0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71,
                subscriptionId: 0,
                callBackLimit: 2e5
            });
    }

    function getLocalConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        MockV3Aggregator mockFeed = new MockV3Aggregator(
            MOCK_DECIMALS,
            MOCK_ANSWER
        );
        VRFCoordinatorV2_5Mock mockVRF = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE,
            MOCK_WEI_LINK
        );
        vm.stopBroadcast();
        return
            NetworkConfig({
                priceFeed: address(mockFeed),
                VrfCoordinator: address(mockVRF),
                keyHash: 0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71,
                subscriptionId: 0,
                callBackLimit: 2e5
            });
    }
}
