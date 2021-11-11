// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IFactory.sol";
import "./ICampaign.sol";

interface IStation {
    event CampaignRegistered(address newAddress);
    
    function getStationMeta() external view returns (string memory meta);

    function listCampaign(ICampaign campaign) external;

    function addSupportedFactory(IFactory factory) external;
}
