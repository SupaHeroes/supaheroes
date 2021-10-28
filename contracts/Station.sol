// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Campaign.sol";
import "./interfaces/IStation.sol";

contract Station is Ownable, IStation {
    string metadata;
    address payable treasury;
    Campaign[] public campaigns;

    constructor(string memory _metadata, address payable _treasury){
        metadata = _metadata;
        treasury = _treasury;
    }

    function getStationMeta() external override view returns(string memory meta){
        return metadata;
    }

    function getAllCampaigns() external view returns(Campaign[] memory){
        return campaigns;
    }

    function startCampaign(
        string memory _projectName, 
        address payable _projectStarter, 
        uint256 _fundingEndTime, 
        uint256 _fundTarget, 
        uint256 _projectEndTime)
        external override{
        Campaign project = new Campaign(
            _projectName, 
            _projectStarter,
            _fundingEndTime,
            _fundTarget,
            _projectEndTime            
        );
        campaigns.push(project);
        emit CampaignCreated(address(this));
    }
}