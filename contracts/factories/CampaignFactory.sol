// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../strategies/StandardCampaignStrategy.sol";
import "../strategies/VestedCampaignStrategy.sol";
import "../interfaces/ICampaign.sol";
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
contract CampaignFactory is Ownable {
    //event used to index created campaigns
    event CampaignCreated(
        address campaignAddress,
        string metadata,
        address indexed currency,
        uint256 fundingEndTime,
        uint256  indexed fundingStartTime,
        uint256 timestamp,
        bool indexed isVested
    );
    event LogCreator(address indexed creator, address campaign);

    //keeping track of the campaign deployer
    mapping(address => mapping(uint256 => StandardCampaignStrategy))
        public deployerOf;

    //number of deployed campaigns
    uint256 public deployedCampaigns;

    function deployStandardCampaign(
        string memory _tokenSymbol,
        string calldata _metadata,
        address _currency,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime,
        uint[] memory _amts,
        string[] memory _agreementData,
        uint[] memory _limits,
        address rewardManager
    ) external returns (bool) {
        require(_amts.length == _limits.length && _amts.length == _agreementData.length, "Bad UI implementation");
        //deploy the campaign
        StandardCampaignStrategy project = new StandardCampaignStrategy(
            _tokenSymbol,
            address(this),
            _currency,
            _metadata,
            msg.sender,
            _fundingEndTime,
            _fundTarget,
            _fundingStartTime
        
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
            block.timestamp,
            false
        );
        //createAgreement
        RewardManager(rewardManager).whitelistCampaign(project);
        for(uint i = 0; i < _amts.length; i++){
            RewardManager(rewardManager).createAgreement(_amts[i], _limits[i], _agreementData[i], address(project), msg.sender);
        }
        return true;
    }

    function deployVestedCampaign(
        string memory _tokenSymbol,
        string calldata _metadata,
        address _currency,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime,
        VestedCampaignStrategy.Vest[] calldata _vests,
        uint[] memory _amts,
        string[] memory _agreementData,
        uint[] memory _limits,
        address rewardManager
    ) external returns (bool) {
         require(_amts.length == _limits.length && _amts.length == _agreementData.length, "Bad UI implementation");
         require(_vests.length > 0);
        //create vested campaign
        VestedCampaignStrategy project = new VestedCampaignStrategy(
            _tokenSymbol,
            address(this),
            _currency,
            _metadata,
            msg.sender,
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
            block.timestamp,
            true
        );
        //createAgreement
        RewardManager(rewardManager).whitelistCampaign(project);
        for(uint i = 0; i < _amts.length; i++){
            RewardManager(rewardManager).createAgreement(_amts[i], _limits[i], _agreementData[i], address(project), msg.sender);
        }
        return true;
    }
}
