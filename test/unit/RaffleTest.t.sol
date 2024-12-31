// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "../../script/HelperConfig.s.sol";



contract RaffleTest is CodeConstants, Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
    uint266 entranceFee;
    uint256 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 raffleEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2_5;
    LinkToken link;

    //makeAddr is a cheat code that generates address
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;


       vm.deal(PLAYER, STARTING_PLAYER_BALANCE);  
    }

    function testRaffleInitializesInOpenState() public veiw {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        //Then we follow Arrange, Act, Assert
        //Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: entranceFee}();
        //Asset
        address  playerRecorded =  raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

function testEnteringRaffleEmitsEvent() public {
//Arrange
vm.prank(PLAYER);
//Act
vm.expectEmit(true, false, false, false, address(raffle));
emit RaffleEntered(PLAYER);
//Assert
raffle.enterRaffle{value: entranceFee}();

}

function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
//Arrange
vm.prank(PLAYER);
raffle.enterRaffle{value: entranceFee}();
//vm.warp is used to adjust the timeStamp
vm.warp(block.timestamp + interval + 1);
//vm.roll changes the current block number
vm.roll(block.number + 1);
raffle.performUpkeep("");
//Act //Assert
vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
vm.prank(PLAYER);
raffle.enterRaffle{value: entranceFee}();
} 

function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
//Arrange
vm.warp(block.timestamp + interval + 1);
vm.roll(block.number + 1);

//Act
(bool upKeepNeeded, ) = raffle.checkUpkeep("");


//Assert
assert(!upKeepNeeded);
}
function testCheckUpkeepReturnsFalseIfRaffleIsntOpen()public{
//Arrange
vm.prank(PLAYER);
raffle.enterRaffle{value: entranceFee}();
//vm.warp is used to adjust the timeStamp
vm.warp(block.timestamp + interval + 1);
//vm.roll changes the current block number
vm.roll(block.number + 1);
raffle.performUpkeep("");
//Act

(bool upKeepNeeded, ) = raffle.checkUpkeep("");
//Assert
assert(!upKeepNeeded);
}

//Challenge
//testCheckUpKeepReturnsFalseIfEnoughTimeHasPassed
//testCheckUpKeepReturnsTrueWhenParametersAreGood
//Now we test perform upkeep
function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue()public{
//Arrange
vm.prank(PLAYER);
raffle.enterRaffle{value: entranceFee}();
//vm.warp is used to adjust the timeStamp
vm.warp(block.timestamp + interval + 1);
//vm.roll changes the current block number
vm.roll(block.number + 1);

//Act / Assert
raffle.performUpkeep("");
}

function testPerformUpKeepRevertsIfCheckUpKeepIsFalse()public {
//Arrange
uint256 currentBalance = 0;
uint256 numPlayers = 0;
Raffle.RaffleState rState = raffle.getRaffleState();

vm.prank(PLAYER);
raffle.enterRaffle{value: entranceFee}();
currentBalance = currentBalance + entranceFee;
numPlayers = 1;

//Act / Assert
vm.expectRevert(
abi.encode(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance,
 numPlayers, rState );

);
raffle.perfromUpKeep("");

}
modifier raffleEntered(){
//Arrange
vm.prank(PLAYER);
raffle.enterRaffle{value: entranceFee}();
//vm.warp is used to adjust the timeStamp
vm.warp(block.timestamp + interval + 1);
//vm.roll changes the current block number
vm.roll(block.number + 1);
_;

} 


//What if we need to get data from the emitted events in our tests? 

function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()public raffleEntered{
// //Arrange
// vm.prank(PLAYER);
// raffle.enterRaffle{value: entranceFee}();
// //vm.warp is used to adjust the timeStamp
// vm.warp(block.timestamp + interval + 1);
// //vm.roll changes the current block number
// vm.roll(block.number + 1);

//Act
//Now we record all the logs using foundry
vm.recordLogs();
//vm.recordLogs means keeping track of logs emitted by performUpKeep function
raffle.performUpkeep("");
Vm.Log[] memory entries = vm.getRecordedLogs();
bytes32 requestId = entries[1].topics[1];

//Assert
Raffle_RaffleState raffleState = raffle.getRaffleState();
assert(uint256(requestId)>0);
assert(uint256(raffleState)==1);

}

modifier skipFork(){
if(block.chainid != LOCAL_CHAIN_ID){
  return;  
}
_;
}



//Fufilling Random words
function testFulfillrandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) 
public raffleEntered
skipFork {
//Arrange /Act /Assert
vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));


//Now we use Fuzz test instead of test each numbers
// vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
// VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1, address(raffle));

// vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
// VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(2, address(raffle));
}


function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEntered{
//Arrange
uint256 additionalEntrants = 3; //4 people in total entered
uint256 startingIndex = 1;
address expectedWinner = address(1);
 
for(uint256 i = startingIndex; i<startingIndex + additionalEntrants; i++){
    address newPlayer =address(uint160(i)); 
//Now we give new players some Eth 
hoax(newPlayer, 1 ether);
raffle.enterRaffle{value: entranceFee} ();  
}

uint256 startingTimeStamp = raffle.getLastTimeStamp();
unit256 winnerStartingBalance = expectedWinner.balance;




//Act
//Now we record all the logs using foundry
vm.recordLogs();
//vm.recordLogs means keeping track of logs emitted by performUpKeep function
raffle.performUpkeep("");
Vm.Log[] memory entries = vm.getRecordedLogs();
bytes32 requestId = entries[1].topics[1];
VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

//Assert
address recentWinner = raffle.getRecentWinner();
Raffle.RaffleState raffleState = raffle.getRaffleState();
uint256 winnerBalance = recentWinner.balance;
uint256 endingTimeStamp = raffle.getLastTimeStamp();
uint256 prize = entranceFee * (additionalEntrants +1);


assert(recentWinner == expectedWinner);
assert(uint256(raffleState) == 0);
assert(WinnerBalance == winnerStartingbalance + prize);
assert(endingTimeStamp > startingTimeStamp);
}

}
