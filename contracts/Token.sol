// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SupaToken is ERC20 {
    string private constant ERC20_SYMBOL = "SUPA";
    string private constant ERC20_NAME = "SupaToken";
    constructor() ERC20(ERC20_NAME, ERC20_SYMBOL) {
        _mint(msg.sender, 10000000000 * 10**uint(decimals()));
    }
}