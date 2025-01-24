// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mocks/MocksV3Aggregator.sol";

contract HelperConfig is Script {
    
    NetworkConfig public activeNetworkConfig;
    uint8 constant DECIMALS = 8; 
    int256 constant INITIAL_PRICE = 2000e8;


    struct NetworkConfig {
        address priceFeed;
    }
    
    constructor() {
        if(block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if(block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

        function getMainnetEthConfig() public pure returns(NetworkConfig memory) {
        // price feed address
        NetworkConfig memory ethMainnetConfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return ethMainnetConfig;
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory) {
        if(activeNetworkConfig.priceFeed != address(0)) { // the address already initialized, it is not zero
            return activeNetworkConfig;
        }
        // price feed address
        vm.startBroadcast();
        MockV3Aggregator mocksPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mocksPriceFeed)});
        vm.stopBroadcast();
        return anvilConfig;
    }
}
