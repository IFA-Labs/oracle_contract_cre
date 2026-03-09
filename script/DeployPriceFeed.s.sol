//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IfaPriceFeed} from "../src/IfaPriceFeed.sol";
import {IfaPriceFeedVerifier} from "src/IfaPriceFeedVerifiers.sol";

contract DeployPriceFeed is Script {
    IfaPriceFeed ifaPriceFeed;
    IfaPriceFeedVerifier ifaPriceFeedVerifier;

    bytes32 constant SALT_IfaPriceFeed = keccak256("ifaPriceFeeeed");
    bytes32 constant SALT_ifaPriceFeedVerifier = keccak256("ifaPriceFeeedVerifieer");

    address constant Base_Sepolia_Simulation_Testnet = 0x82300bd7c3958625581cc2F77bC6464dcEcDF3e5;
    address constant Ethereum_Sepolia_Simulation_Testnet = 0x15fC6ae953E024d975e77382eEeC56A9101f9F88;

    function run() public {
        vm.startBroadcast();

        console.log("Deploying from:", msg.sender);
        console.log("Chain ID:", block.chainid);

        address owner = msg.sender;
        address forwarder = _getForwarder(block.chainid);

        _deployOracle(owner, forwarder);

        vm.stopBroadcast();
    }

    function _getForwarder(uint256 chainId) internal pure returns (address) {
        if (chainId == 84532) {
            // Base Sepolia
            return Base_Sepolia_Simulation_Testnet;
        }

        if (chainId == 11155111) {
            // Ethereum Sepolia
            return Ethereum_Sepolia_Simulation_Testnet;
        }

        revert("Unsupported chain");
    }

    function _deployOracle(address owner, address forwarder) internal {
        ifaPriceFeed = new IfaPriceFeed(owner);

        console.log("IfaPriceFeed deployed at:", address(ifaPriceFeed));
        console.log("Owner:", ifaPriceFeed.owner());

        ifaPriceFeedVerifier = new IfaPriceFeedVerifier(
            address(0xCCB3f2CC8592126a80B91B53eE4d7332F54d980d), address(ifaPriceFeed), owner, forwarder
        );

        console.log("IfaPriceFeedVerifier deployed at:", address(ifaPriceFeedVerifier));

        ifaPriceFeed.setVerifier(address(ifaPriceFeedVerifier));
    }
}
