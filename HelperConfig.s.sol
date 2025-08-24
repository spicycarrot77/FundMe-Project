// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Deploy mocks when we are on a local chain
// keep track of contract addresses across different chains
// return the right address based on the chain we are on

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {

    struct NetworkConfig {
        address priceFeed;
    }
    NetworkConfig public activeNetworkConfig;

    uint256 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 11155111) {  //this is the chain id of sepolia
            activeNetworkConfig = getSepoliaEthConfig();
        } elseif (block.chainid == 1)
         {
        //this is the chain id of mainnet
            activeNetworkConfig = getMainnetEthConfig();
            }
         else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //this will return configuration for Sepolia addresses 
        //will return price feed address
        // vrf address, 
        // link addres 
        // gas price   so for this we need to create a struct
        return NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
    }

    function getOrCreateAnvilEthConfig() public pure returns (NetworkConfig memory) {
        // for local anvil chain, we deploy mocks(dummycontract) and return the mock address
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // 1. Deploy the mocks
        // 2. Return the mock address
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        return NetworkConfig({priceFeed: address(mockPriceFeed)});
    }
     function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
    }

}