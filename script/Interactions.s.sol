// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/Mock/TestLink.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract Interaction is Script {
    function createSubscriptionbyConifg() public returns (uint256, address) {
        // Create a new subscription
        // Add the consumer contract to the subscription
        // Fund the subscription with LINK tokens
        HelperConfig helperConfig = new HelperConfig();
        address vrfaddress = helperConfig.getconfig().vrfCoordinator;

        (uint256 subId, address vrfaddress1) = createsub(vrfaddress);
        return (subId, vrfaddress1);
    }

    function createsub(address vrfaddress) public returns (uint256, address) {
        // vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = VRFCoordinatorV2_5Mock(
            vrfaddress
        );

        uint256 subId = vrfCoordinator.createSubscription();
        // vm.stopBroadcast();

        // Add the consumer contract to the subscription
        // Fund the subscription with LINK tokens
        return (subId, vrfaddress);
    }

    function run() external {
        createSubscriptionbyConifg();
    }
}

contract fundSubscription is Script {
    function fundSubscriptionusingconfig() public {
        HelperConfig helperConfig = new HelperConfig();
        console.log("SubID: %s", helperConfig.getconfig().subscriptionId);
        console.log(
            "VRF Coordinator: %s",
            helperConfig.getconfig().vrfCoordinator
        );
        console.log("LINK Token: %s", helperConfig.getconfig().LINK);
        fundsub(
            helperConfig.getconfig().vrfCoordinator,
            helperConfig.getconfig().subscriptionId,
            helperConfig.getconfig().LINK
        );
    }

    function fundsub(
        address vrfCoordinator,
        uint256 subId,
        address link
    ) public {
        uint96 amount = 10 ether;
        if (block.chainid == 11155111) {
            console.log("Funding subscription on Sepolia...");
            // Implement the logic to fund the subscription on Sepolia
            // vm.startBroadcast();
            LinkToken linkToken = LinkToken(link);
            linkToken.transferAndCall(
                vrfCoordinator,
                amount,
                abi.encode(subId)
            );
            // vm.stopBroadcast();
        } else {
            console.log("Funding subscription on local network...");
            // Implement the logic to fund the subscription on a local network
            // vm.startBroadcast();
            VRFCoordinatorV2_5Mock vrfCoordinatorMock = VRFCoordinatorV2_5Mock(
                vrfCoordinator
            );
            vrfCoordinatorMock.fundSubscription(subId, amount);
            // vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionusingconfig();
    }
}

contract addconsumers is Script {
    function addconsumerbyconfig(address consumer) public {
        HelperConfig helperConfig = new HelperConfig();
        addconsumer(
            consumer,
            helperConfig.getconfig().subscriptionId,
            helperConfig.getconfig().vrfCoordinator
        );
    }

    function addconsumer(
        address consumer,
        uint256 subId,
        address vrfCoordinator
    ) public {
        console.log("Adding consumer to subscription...", consumer);
        console.log("VRF Coordinator: %s", vrfCoordinator);
        console.log("Subscription ID: %s", subId);
        // vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = VRFCoordinatorV2_5Mock(
            vrfCoordinator
        );
        vrfCoordinatorMock.addConsumer(subId, consumer);
        // vm.stopBroadcast();
    }

    function run() external {
        address mostrectlydeplyedcontract = DevOpsTools
            .get_most_recent_deployment("Raffle", block.chainid);
        addconsumerbyconfig(mostrectlydeplyedcontract);
    }
}
