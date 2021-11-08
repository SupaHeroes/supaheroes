// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ICampaign.sol";

interface IStation {
    event CampaignCreated(address newAddress);
    event CampaignRegistered(address newAddress);

    function getStationMeta() external view returns (string memory meta);

    function registerCampaign(ICampaign campaign) external returns (bool result);
}
