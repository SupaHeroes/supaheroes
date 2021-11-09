// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStation.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IStrategy.sol";
import "./Campaign.sol";
import "./governance/Headquarter.sol";

contract Station is Ownable, IStation {
    string metadata_uri;
    Headquarter public immutable headquarter;
    address payable treasury;

    mapping(uint => Campaign) campaigns;

    IFactory[] public campaignFactories;

    uint listedCampaignCount;

    constructor(string memory _metadata, address payable _treasury, Headquarter hq){
        hq.registerStation();
        headquarter = hq;
        metadata_uri = _metadata;
        treasury = _treasury;
    }

    function addSupportedFactory(IFactory factory) external override onlyOwner {
        campaignFactories.push(factory);
    }

     function listCampaign(Campaign campaign) external override {
         campaigns[listedCampaignCount] = campaign;
         listedCampaignCount += 1;
     }

    function getStationMeta() external override view returns(string memory meta){
        return metadata_uri;
    }

    function changeStationMeta(string memory newMeta) external onlyOwner{
        metadata_uri = newMeta;
    }

    // function getAllCampaigns() external view returns(IFactory.Campaign[] memory){
    //     return campaigns;
    // }

}