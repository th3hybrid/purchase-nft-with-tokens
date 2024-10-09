// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {AirplaneNft} from "src/AirplaneNft.sol";
import {AceToken} from "src/AceToken.sol";
import {DeployAceToken} from "./DeployAceToken.s.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployAirplaneNft is Script {
    AirplaneNft airplaneNft;
    uint256 private constant PRICE = 250 * 1e18;

    function run() external returns (AirplaneNft, AceToken) {
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        DeployAceToken deployer = new DeployAceToken();
        AceToken paymentToken = deployer.run();
        vm.startBroadcast();
        airplaneNft = new AirplaneNft(ethUsdPriceFeed, paymentToken, PRICE);
        vm.stopBroadcast();
        return (airplaneNft, paymentToken);
    }
}
