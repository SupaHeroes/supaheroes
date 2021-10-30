// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./Campaign.sol";

contract CampaignBento is Campaign {
    constructor(
        string memory _metadata,
        address payable _treasury,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime
    )
        Campaign(
            _metadata,
            _treasury,
            _fundingEndTime,
            _fundTarget,
            _fundingStartTime
        )
    {
        // Custom campaign contract here
    }
}
