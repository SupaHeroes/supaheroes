// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../strategies/StandardCampaignStrategy.sol";
import "../VestingManager.sol";
import "../RewardManager.sol";

/* 
    CampaignFactory for Supaheroes.org
    Author: Axel Devara
        
    ███████████████████████████████████████████████████████████
    █─▄▄▄▄█▄─██─▄█▄─▄▄─██▀▄─██─█─█▄─▄▄─█▄─▄▄▀█─▄▄─█▄─▄▄─█─▄▄▄▄█
    █▄▄▄▄─██─██─███─▄▄▄██─▀─██─▄─██─▄█▀██─▄─▄█─██─██─▄█▀█▄▄▄▄─█
    ▀▄▄▄▄▄▀▀▄▄▄▄▀▀▄▄▄▀▀▀▄▄▀▄▄▀▄▀▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
    
    A factory contract to create campaign from various strategies and also making the agreements
    for RewardManager contract. This contract is crucial to the frontend because most of the events
    for indexing will come from this contract. In the future, an iteration based on Proxy architecture
    can be made to save gas.
    */
contract CampaignFactory  {
    //event used to index created campaigns
    event CampaignCreated(
        address campaignAddress,
        string metadata,
        address indexed currency,
        uint256 indexed fundingEndTime,
        uint256 indexed fundingStartTime,
        uint256 timestamp
    );
    event LogCreator(address indexed creator, address campaign);

    //keeping track of the campaign deployer
    mapping(address => address) public deployerOf;

    //number of deployed campaigns
    uint256 public deployedCampaigns;

    function deployStandardCampaign(
        string calldata _metadata,
        address _currency,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime
    ) external returns (bool) {
        //deploy the campaign
        StandardCampaignStrategy project = new StandardCampaignStrategy(
            address(this),
            _currency,
            _metadata,
            msg.sender,
            _fundingEndTime,
            _fundTarget,
            _fundingStartTime
        );

        deployerOf[address(project)] = msg.sender;
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

    function deployVestingManager(VestingManager.Vest[] calldata vestings, address campaign) external {
        require(msg.sender == deployerOf[campaign]);
        VestingManager _vestingManager = new VestingManager(vestings, ICampaign(campaign), msg.sender);
        ICampaign(campaign).whitelistVestingManager(address(_vestingManager));
    }

    function deployRewardManager(address campaign, string calldata uri, uint256[] calldata quantities) external {
        require(msg.sender == deployerOf[campaign]);
        RewardManager _rewardManager = new RewardManager(campaign, msg.sender, uri, quantities);
        ICampaign(campaign).whitelistRewardManager(address(_rewardManager));
    }
}
