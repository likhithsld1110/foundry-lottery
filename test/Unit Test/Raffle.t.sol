// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../../test/Mock/TestLink.sol";
import {Vm} from "forge-std/Vm.sol";

contract Raffletest is Script {
    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 public entranceFee;
    uint256 public interval;
    address public vrfCoordinator;
    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    address public new_player = makeAddr("player");
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deploycontractRaffle();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getconfig();
        entranceFee = networkConfig.entranceFee;
        interval = networkConfig.interval;
        vrfCoordinator = networkConfig.vrfCoordinator;
        keyHash = networkConfig.keyHash;
        callbackGasLimit = networkConfig.callbackGasLimit;
        // vm.prank(new_player);
        // vm.deal(new_player, 10 ether);
    }

    function testRafflestate() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRevertsWhenNotEnoughETHEntered() public addmoneyandaddress {
        vm.expectRevert(Raffle.Raffle__NotEnoughETHEntered.selector);
        raffle.enterRaffle();
    }

    function testplayeraddedtoarray() public addmoneyandaddress {
        raffle.enterRaffle{value: 1 ether}();
        address player = raffle.getplayers(0);
        assert(player == new_player);
    }

    function testemitRaffleenetered() public addmoneyandaddress {
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEnter(new_player);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testuserdontenterwhilecalculation() public addmoneyandaddress {
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.pickWinner(); //perform upkeep to change the state to calculating
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(new_player);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testupkeepreturnsfalseifithasnobalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        bool upKeepNeeded = raffle.checkUpKeep();
        assert(upKeepNeeded == false);
    }

    function testupkeepreturnsfalseifraffleisnotopen()
        public
        addmoneyandaddress
    {
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.pickWinner(); //perform upkeep to change the state to calculating
        bool upKeepNeeded = raffle.checkUpKeep();
        assert(upKeepNeeded == false);
    }

    function testupkeepreturnsfalseifenoughtimehasnotpassed()
        public
        addmoneyandaddress
    {
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval - 10);
        bool upKeepNeeded = raffle.checkUpKeep();
        assert(upKeepNeeded == false);
    }

    function testupkeepreturnstrueeveryparameterpass()
        public
        addmoneyandaddress
    {
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        bool upkeepNeeded = raffle.checkUpKeep();
        assert(upkeepNeeded);
    }

    ////TEST PERFORMUPKEEP
    function testperformupkeeponlyrunsifupkeepneeded()
        public
        addmoneyandaddress
    {
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.pickWinner();
    }

    function testperformupkeeprevertsifupkeepnotneeded()
        public
        addmoneyandaddress
    {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState raffleState = Raffle.RaffleState.OPEN;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpKeepNotNeeded.selector,
                address(raffle).balance,
                numPlayers,
                uint256(raffleState)
            )
        );
        raffle.pickWinner();
    }

    function testrafllepickwinnerorperdormupkeepemitsandchangesState()
        public
        addmoneyandaddress
    {
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.recordLogs();
        raffle.pickWinner();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestid = entries[1].topics[1];
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
        assert(uint256(requestid) > 0);
    }

    /////FULLFILLRANDOM WORDS TEST

    modifier skipfork() {
        if (block.chainid == 11155111) {
            return;
        }
        _;
    }

    function testfullfillrandomwordsonlyrunsafterperformupkeep(
        uint256 requestId
    ) public RaffleEntered skipfork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );
    }

    function testRecentWinner() public addmoneyandaddress skipfork {
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.pickWinner();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            1,
            address(raffle)
        );

        address recentwinner = raffle.getRecentWinner();
        assert(recentwinner == new_player);
    }

    function testfullfillrandomwordsworkandresets()
        public
        RaffleEntered
        skipfork
    {
        //Arrange
        uint256 additionalplayer = 3;
        uint256 startingindex = 1;
        address expectedwinner = address(1);
        for (
            uint256 i = startingindex;
            i < startingindex + additionalplayer;
            i++
        ) {
            address player = address(uint160(i));
            vm.prank(player);
            vm.deal(player, 10 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 currentlastTimeStamp = raffle.getlastTimeStamp();
        uint256 expectedwinnerbalance = expectedwinner.balance;
        //act
        vm.recordLogs();
        raffle.pickWinner();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestid = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestid),
            address(raffle)
        );
        //assert
        address recentwinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 balance = recentwinner.balance;
        uint256 lastTimeStamp = raffle.getlastTimeStamp();
        uint256 prize = entranceFee * (additionalplayer + 1);

        assert(recentwinner == expectedwinner);
        assert(raffleState == Raffle.RaffleState.OPEN);
        assert(balance == expectedwinnerbalance + prize);
        assert(lastTimeStamp > currentlastTimeStamp);
    }

    modifier RaffleEntered() {
        vm.prank(new_player);
        vm.deal(new_player, 10 ether);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier addmoneyandaddress() {
        vm.prank(new_player);
        vm.deal(new_player, 10 ether);
        _;
    }
}
