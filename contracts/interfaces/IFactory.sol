// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ICampaign.sol";
interface IFactory {
    event CampaignCreated(address newAddress);

    function deployCampaign(
        string memory metadata,
        address payable _treasury,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime)
        external;
}
