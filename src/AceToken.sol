// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AceToken is ERC20 {
    constructor(uint256 _initialsupply) ERC20("Ace Token", "AT") {
        _mint(msg.sender, _initialsupply);
    }
}
