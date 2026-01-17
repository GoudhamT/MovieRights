//SPDx-License-Identifier:MIT

pragma solidity 0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

abstract contract ConfigConstants {
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_ID = 31337;
    uint8 public constant MOCK_DECIMALS = 8;
    int256 public constant MOCK_ANSWER = 2000e10;
}

contract HelperConfig is Script, ConfigConstants {
    struct NetworkConfig {
        address priceFeed;
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
                priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            });
    }

    function getLocalConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        MockV3Aggregator mockFeed = new MockV3Aggregator(
            MOCK_DECIMALS,
            MOCK_ANSWER
        );
        vm.stopBroadcast();
        return NetworkConfig({priceFeed: address(mockFeed)});
    }
}
