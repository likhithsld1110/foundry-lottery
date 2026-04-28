// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {fundSubscription, addconsumers} from "./Interactions.s.sol";
import {
    VRFCoordinatorV2_5Mock
} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DeployRaffle is Script {
    function run() external {
        deploycontractRaffle();
    }

    function deploycontractRaffle() public returns (Raffle, HelperConfig) {
        vm.startBroadcast(); // deployer wallet owns EVERYTHING from here
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getconfig();

        if (networkConfig.subscriptionId == 0) {
            // Call createSubscription directly — deployer wallet becomes owner ✅
            networkConfig.subscriptionId = VRFCoordinatorV2_5Mock(networkConfig.vrfCoordinator).createSubscription();

            new fundSubscription()
                .fundsub(networkConfig.vrfCoordinator, networkConfig.subscriptionId, networkConfig.LINK);
        }

        Raffle raffle = new Raffle(
            networkConfig.entranceFee,
            networkConfig.interval,
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId,
            networkConfig.keyHash,
            networkConfig.callbackGasLimit
        );

        // deployer wallet is still broadcaster, so it's the sub owner ✅
        VRFCoordinatorV2_5Mock(networkConfig.vrfCoordinator).addConsumer(networkConfig.subscriptionId, address(raffle));

        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
