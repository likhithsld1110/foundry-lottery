// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {
    VRFCoordinatorV2_5Mock
} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/Mock/TestLink.sol";

abstract contract constansts {
    uint256 public constant SEPOLIA_ID = 11155111;
    uint256 public constant localChainId = 31337;
}

contract HelperConfig is constansts, Script {
    uint96 public constant BASE_FEE = 0.25 ether;
    uint96 public constant GAS_PRICE_LINK = 1e9; // 0.000000001 LINK per gas
    int256 public constant WEI_PER_UNIT_LINK = 1e18; // 1 LINK = 10^18 (18 decimals)
    error InvalidChainId(uint256 chainId);

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        address LINK;
    }
    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainid => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_ID] = getSepoliaethconfig();
    }

    function getConfigbychainid(uint256 chainid) public returns (NetworkConfig memory) {
        if (networkConfigs[chainid].vrfCoordinator != address(0)) {
            return networkConfigs[chainid];
        } else if (chainid == localChainId) {
            return getlocalchainconfig();
        } else {
            revert InvalidChainId(chainid);
        }
    }

    function getconfig() public returns (NetworkConfig memory) {
        return getConfigbychainid(block.chainid);
    }

    function getSepoliaethconfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory SepoliaEthConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 100000,
            subscriptionId: 0,
            LINK: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
        return SepoliaEthConfig;
    }

    function getlocalchainconfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
        //vm.startBroadcast();
        VRFCoordinatorV2_5Mock mockVrfCoordinator =
            new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE_LINK, WEI_PER_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        //vm.stopBroadcast();

        activeNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(mockVrfCoordinator),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 100000,
            subscriptionId: 0,
            LINK: address(linkToken)
        });

        return activeNetworkConfig;
    }
}
