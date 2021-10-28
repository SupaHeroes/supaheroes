// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Station.sol";

contract Headquarter is Ownable {
    Station[] public stations;
    event StationCreated(uint timestamp);
    function deployStation(
        string memory _metaUri)
        public onlyOwner {
        Station project = new Station(
            _metaUri 
        );
        stations.push(project);
        emit StationCreated(block.timestamp);
    }
}