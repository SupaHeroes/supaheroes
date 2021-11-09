// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStrategy.sol";

contract Campaign is Ownable {
    string metadata_uri;
    IStrategy strategy;

    constructor(string memory metadata, IStrategy strat) {
        metadata_uri = metadata;
        strategy = strat;
    }

    function changeMetadata(string memory newMetadata) external {
       metadata_uri = newMetadata;
    }
}