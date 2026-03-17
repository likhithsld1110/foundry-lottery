// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Interaction, fundSubscription, addconsumers} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external {
        deploycontractRaffle();
    }

    function deploycontractRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        addconsumers addConsumer = new addconsumers();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getconfig();
        //
        if (networkConfig.subscriptionId == 0) {
            Interaction interaction = new Interaction();
            (
                networkConfig.subscriptionId,
                networkConfig.vrfCoordinator
            ) = interaction.createsub(
                networkConfig.vrfCoordinator,
                networkConfig.account
            );

            fundSubscription fundSub = new fundSubscription();
            fundSub.fundsub(
                networkConfig.vrfCoordinator,
                networkConfig.subscriptionId,
                networkConfig.LINK,
                networkConfig.account
            );
        }
        vm.startBroadcast(networkConfig.account);
        Raffle raffle = new Raffle(
            networkConfig.entranceFee,
            networkConfig.interval,
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId,
            networkConfig.keyHash,
            networkConfig.callbackGasLimit
        );
        vm.stopBroadcast();

        addConsumer.addconsumer(
            address(raffle),
            networkConfig.subscriptionId,
            networkConfig.vrfCoordinator,
            networkConfig.account
        );
        return (raffle, helperConfig); // Return the raffle and helperConfig instances
    }
}
