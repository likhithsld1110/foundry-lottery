//This scri
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {
    VRFCoordinatorV2_5Mock
} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/Mock/TestLink.sol";

contract DeployRaffle is Script {
    uint96 public constant BASE_FEE = 0.25 ether;
    uint96 public constant GAS_PRICE_LINK = 1e9;
    int256 public constant WEI_PER_UNIT_LINK = 1e18;

    function run() external returns (Raffle, HelperConfig) {
        return deployContractRaffle();
    }

    function deployContractRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        vm.startBroadcast();

        address vrfCoordinator;
        address linkToken;
        uint256 subscriptionId;

        if (block.chainid == 31337) {
            VRFCoordinatorV2_5Mock mockVrfCoordinator =
                new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE_LINK, WEI_PER_UNIT_LINK);
            LinkToken localLinkToken = new LinkToken();

            vrfCoordinator = address(mockVrfCoordinator);
            linkToken = address(localLinkToken);

            subscriptionId = mockVrfCoordinator.createSubscription();
            mockVrfCoordinator.fundSubscription(subscriptionId, 10 ether);
        }

        Raffle raffle = new Raffle(
            0.01 ether,
            30,
            vrfCoordinator,
            subscriptionId,
            0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            100000
        );

        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subscriptionId, address(raffle));

        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
