// SPDX-License-Identifier: MIT
// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

/**
title A simple Raffle contract
author Danny Marvel
@note This contarct is for creating a simple raffle
dev Implements Chainlink VRFv2.5

* */

pragma solidity ^0.8.19;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
//import {console} from "forge-std/Script.sol";


contract Raffle is VRFConsumerBaseV2Plus {
    //Custom Errors
    error Raffle__SendMoreToEnterRaffle();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);




//Enums
enum RaffleState{
  OPEN,  //open will be integer 0
  CALCULATING // calculating will be integer 1

}





//State Variables
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    //immutable gives cheap gas fee, however you cannot change it
    uint256 private immutable i_entraceFee;
    //The Duration of the lottery in seconds
    uint256 private immutable i_interval;
    bytes32 private immutable i_KeyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    //To get the list of players who enters the game
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;// start as open
   
   bool s_calculatingWinner = false;
   
   
    //Events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entraceFee = entranceFee;
        i_interval = interval;
        i_KeyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;


        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        // s_vrfCoordinator.requestRandomWords
    }

    function enterRaffle() external payable {
        //If we store the error as a string "Not enough ETH sent"
        //It will cost a lot of gas
        //  require(msg.value >= i_entraceFee, 'Not enough ETH sent!');
        //  require(msg.value >= i_entraceFee, SendMoreToEnterRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
     if(s_raffleState != RaffleState.OPEN) {
    //By this you can only enter the Raffle if it is opened    
        revert Raffle_RaffleNotOpen();
     }
     s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender); }

//This is the function that Chainlink nodes will call to see
//if the lottery is ready to have a winner picked
//The following should be true in order for upKeepNeeded to be true
//The time interval has passed betwween the raffle runs
//The lottery is open
//The contract has ETH
//Implicitly, your subscription has LINK
//upKeepNeeede- true if its time to restart the lottery


function checkUpKeep(bytes memory /*checkData*/ ) public view 
returns (bool upKeepNeeded, bytes memory /*performData*/ ) 

{
 //Gets the current block time
  bool timeHasPassed  = ((block.timestamp - s_lastTimeStamp) >= i_interval) ;
  bool isOpen = s_raffleState == RaffleState.OPEN;
  bool hasBalance = address(this).balance > 0;
  bool hasPlayers = s_players.length >0;
  upKeepNeeded = timeHasPassed && isOpen && hasBalance & hasPlayers;
  return (upKeepNeeded, '')

}

/**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
     
     function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

}








    //1. Get a random number
    //2. Use the random number to pick a player
    //3. Be automatically called
    function pickWinner() external {
        //check to see if enough time has passed

        //Gets the current block time
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
            //Get our random number 2.5
            // 1. Make a Request RNG
            // 2. Get RNG
        }

    s_raffleState = RaffleState.CALCULATING;
            // Will revert if subscription is not set and funded.
            uint256 requestId = s_vrfCoordinator.requestRandomWords(
                VRFV2PlusClient.RandomWordsRequest({
                    keyHash: i_gasLane,
                    subId: i_subscriptionId,
                    requestConfirmations: REQUEST_CONFIRMATIONS,
                    callbackGasLimit: i_callbackGasLimit,
                    numWords: NUM_WORDS,
                    extraArgs: VRFV2PlusClient._argsToBytes(
                        // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                        VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                    )
                })
            );
            // Quiz... is this redundant?
            emit RequestedRaffleWinner(requestId);
            uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        }
       
    

   //CEI: Checks, Effects, Interactions Patterns
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        // s_player = 10
        // 12 % 10 = 2 

   //Effect (Internal Contract State)     
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
    //This Resets the players    
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
          emit WinnerPicked(s_recentWinner);


  //Interactions (External Contract Interactions)      
        (bool success) = recentWinner.call{value: address(this).balance}('');
       if (!success) {
         revert Raffle_TransferFailed();

       } 
     
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entraceFee;
    }

function getRaffleState() external view returns (RaffleState){
 return s_raffleState;
}
//Add function to get the players
function getPlayer(uint256 indexOfPlayer) external view returns(address){
return s_players[indexOfPlayers];
}

function getLastTimeStamp() external view returns(uint256){
returns s_lastTimeStamp;

}

function getRecentWinner() external view returns(address){
    return s_recentWinner;
}
    
}
