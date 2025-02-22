// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";


abstract contract CodeConstants{
 /*VRF Mock Values */ 
 uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    address public FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_CHAIN_ID = 31337;




}


contract HelperConfig is CodeConstants, Script {
 error HelperConfig_InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        uint256 automationUpdateInterval;
        uint256 raffleEntranceFee;
        address vrfCoordinatorV2_5;
        address link;
        address account;
    }
  NetworkConfig public  localNetworkConfig;
  mapping(uint256 chainId => NetworkConfig) public  NetworkConfigs;

  constructor(){
 NetworkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();


  }
  


function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){
  if(networkConfigs[chainId].vrfCoordinator != address(0)){
   return networkConfigs[chainId]; 
  } else if (chainId == LOCAL_CHAIN_ID){
// Deploying some mocks
  return getOrCreateAnvilEthConfig();


}
else { 
 revert HelperConfig_InvalidChainId();

}
}

function getConfig() public returns(NetworkConfig memory){
   return getConfigByChainId(block.chainid);

}




  function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
  return NetworkConfig (
{
            subscriptionId: subscriptionId,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            automationUpdateInterval: 30, // 30 seconds
            raffleEntranceFee: 0.01 ether,
            callbackGasLimit: 500000, // 500,000 gas
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
})
}

function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory){
//  Check to see if we set an active network config
if(localNetworkConfig.vrfCoordinator != address(0)){
    return localNetworkConfig;
}
//Then we Deploy mocks and such
vm.startBroadcast();
VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
  MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK
);
LinkToken linkToken = new LinkToken();
vm.stopBroadcast();
localNetworkConfig = NetworkConfig({
          entranceFee : 0.01 ether,
            subscriptionId: subscriptionId,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            automationUpdateInterval: 30, // 30 seconds
            raffleEntranceFee: 0.01 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: address(vrfCoordinatorV2_5Mock),
            link: address(link),
            account: FOUNDRY_DEFAULT_SENDER
});
return localNetworkConfig;




}



}
