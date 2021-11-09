// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Station.sol";
import "../interfaces/IStation.sol";

contract Headquarter is Ownable {
    event RegisteredStationLog(address indexed protocol);
    event StationCreated(address indexed stationContract, bool approved);

    IStation[] public stations;
    mapping (IStation => bool) approvedStations;

    function registerStation() public {
        stations.push(IStation(msg.sender));
        emit RegisteredStationLog(msg.sender);
    }

    function approveStation(uint index, bool approve) external onlyOwner {
        approvedStations[stations[index]] = approve;
    }

}