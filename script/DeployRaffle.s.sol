// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from 'forge-std/Script.sol';
import {Raffle} from 'src/Raffle.sol';
import {HelperConfig} from 'script/HelperConfig.s.sol';
import {CreateSubscription, FundSubscripton, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
function run() public {
  deployContract();
}

function deployContract() public returns (Raffle,  HelperConfig){
  HelperConfig helperConfig =  new HelperConfig();
//local > deploy mocks, get local config
//sepolia > get sepolia config 
 HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

if (config.subscriptionId == 0){
//Then we create subscription ID
CreateSubscription createSubscription = new CreateSubscription();
(config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator,
config.account);
//Then we fund it

FundSubscription fundSubscription = new FundSubscription();
fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link,
config.account);


}



vm.startBroadcast(config.account);
Raffle raffle = new Raffle(
config.entranceFee,
config.interval, 
config.vrfCoordinator,
config.gasLane,
config.subscriptionId,
config.callbackGasLimit
);
vm.stopBroadcast();
AddConsumer addConsumer = new AddConsumer();
//we do not need to broadcast, cause in our consumer we already broadcasted
addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, 
config.account);

return (raffle, helperConfig);
}
}