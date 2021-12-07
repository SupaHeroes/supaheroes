// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../strategies/StandardCampaignStrategy.sol";
import "../interfaces/ICampaign.sol";

contract StandardCampaignFactory is Ownable {
    //event used to index created campaigns
    event CampaignCreated(
        address indexed campaignAddress,
        string metadata,
        address indexed currency,
        uint256 fundingEndTime,
        uint256 indexed fundingStartTime,
        uint256 timestamp
    );
    event LogCreator(address indexed creator, address campaign);

    //keeping track of the campaign deployer
    mapping(address => mapping(uint256 => StandardCampaignStrategy))
        public deployerOf;

    //number of deployed campaigns
    uint256 public deployedCampaigns;

    function deployCampaign(
        string calldata _metadata,
        address _currency,
        address _admin,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime,
        StandardCampaignStrategy.Vest[] calldata _vests
    ) external returns (bool) {
        //check if there is any vesting
        StandardCampaignStrategy project = new StandardCampaignStrategy(
            address(this),
            _currency,
            _metadata,
            _admin,
            _fundingEndTime,
            _fundTarget,
            _fundingStartTime,
            _vests
        );

        deployerOf[msg.sender][deployedCampaigns] = project;
        emit LogCreator(msg.sender, address(project));
        deployedCampaigns += 1;
        emit CampaignCreated(
            address(this),
            _metadata,
            _currency,
            _fundingEndTime,
            _fundingStartTime,
            block.timestamp
        );
        return true;
    }
}
