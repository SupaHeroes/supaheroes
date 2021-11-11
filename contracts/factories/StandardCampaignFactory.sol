// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../strategies/StandardCampaignStrategy.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/ICampaign.sol";

contract StandardCampaignFactory is Ownable, IFactory {
    mapping(uint => StandardCampaignStrategy) public campaigns;
    mapping(address => mapping(uint => StandardCampaignStrategy)) public deployerOf;

    uint256 public deployedCampaigns;

    function getAllCampaigns() external view returns(StandardCampaignStrategy[] memory){
        StandardCampaignStrategy[] memory campaignList = new StandardCampaignStrategy[](deployedCampaigns);
    for (uint i = 0; i < deployedCampaigns; i++) {
        campaignList[i] = campaigns[i];
    }
    return campaignList;
    }
    

    function deployCampaign(
        string memory metadata,
        address payable _treasury,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime)
        external override{
        StandardCampaignStrategy project =  new StandardCampaignStrategy(
            this,
            metadata,
            _treasury, 
            _fundingEndTime,
            _fundTarget,
            _fundingStartTime            
    );
        campaigns[deployedCampaigns] = project;
        deployerOf[msg.sender][deployedCampaigns] = project;
        deployedCampaigns += 1;
        emit CampaignCreated(address(this));
    }
}