// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Station.sol";
import "../interfaces/IStation.sol";

contract Headquarter is Ownable {
    event StationCreated(address indexed stationContract, bool approved);

    Station[] public stations;
    mapping (address => bool) approvedStations;

    function registerStation(IStation station) public {

    }
}