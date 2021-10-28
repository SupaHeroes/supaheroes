// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ICampaign.sol";

interface IStation {
    event CampaignCreated(address newAddress);

    function getStationMeta() external view returns (string memory meta);

    function startCampaign(
        string memory _projectName,
        address payable _projectStarter,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _projectEndTime
    ) external;
}
