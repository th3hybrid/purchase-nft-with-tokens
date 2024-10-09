// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {AceToken} from "src/AceToken.sol";

contract DeployAceToken is Script {
    AceToken aceToken;
    uint256 private constant INITIAL_SUPPLY = 1_000_000 * (10 ** 18);

    function run() external returns (AceToken) {
        vm.startBroadcast();
        aceToken = new AceToken(INITIAL_SUPPLY);
        vm.stopBroadcast();
        return aceToken;
    }
}
