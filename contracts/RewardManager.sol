// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/ICampaign.sol";

/* 
    Reward Manager for Supaheroes.org
    Author: Axel Devara
        
    ███████████████████████████████████████████████████████████
    █─▄▄▄▄█▄─██─▄█▄─▄▄─██▀▄─██─█─█▄─▄▄─█▄─▄▄▀█─▄▄─█▄─▄▄─█─▄▄▄▄█
    █▄▄▄▄─██─██─███─▄▄▄██─▀─██─▄─██─▄█▀██─▄─▄█─██─██─▄█▀█▄▄▄▄─█
    ▀▄▄▄▄▄▀▀▄▄▄▄▀▀▄▄▄▀▀▀▄▄▀▄▄▀▄▀▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
    
    Creates a Supahero Contributor Certificate (SCC) as a proof of contribution. The certificate 
    is meant to be platform specific, in this case, Supaheroes. For now, certificate is awarded manually
    by campaign admin. Feel free to fork/PR this contract.
    */
contract RewardManager is ERC1155, Ownable {    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) internal whitelistedCaller;
    mapping(address => bool) internal whitelistedCampaign;
    mapping(address => Agreement[]) public campaignToAgreements;
    mapping(uint256 => Certificate) public tokenIdtoCertificate;

    struct Certificate {
        string name;
        string projectName;
        uint256 amount;
        address currency;
        uint256 timestamp;
    }

    struct Agreement {
        uint256 amount;
        uint256 limit;
        uint256 redeemCount;
        address admin;
        mapping(address => uint) rewardDistribution;
        mapping(address => string) rewardData;
        string metadata;
    }

    constructor() ERC1155("") {
        
    }

    function setUri(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    function whitelistCaller(address caller) external onlyOwner {
        whitelistedCaller[caller] = true;
    }

    function whitelistCampaign(ICampaign campaignAddress) external {
        require(whitelistedCaller[msg.sender]);
        whitelistedCampaign[address(campaignAddress)] = true;
    }

    function createAgreement(uint _amt, uint _limit, string memory _metadata, address _campaign, address _admin) external {
        require(whitelistedCaller[msg.sender]);
        Agreement storage newAgreement = campaignToAgreements[_campaign][campaignToAgreements[_campaign].length];
            newAgreement.amount = _amt;
            newAgreement.limit = _limit;
            newAgreement.metadata = _metadata;
            newAgreement.admin = _admin;
    }

    function registerForRedeem(address campaignAddress, uint256 agreementId, string memory userData) external {
        require(campaignAddress != address(0), "Empty address");
        require(whitelistedCampaign[campaignAddress], "Campaign is not registered");
        require(campaignToAgreements[campaignAddress].length > agreementId, "Wrong argument Id");
        Agreement storage agreement = campaignToAgreements[campaignAddress][agreementId];
        require(IERC20(campaignAddress).balanceOf(msg.sender) >= agreement.amount, "You don't have enough balance");
        require(msg.sender != agreement.admin, "Admin should not participate");
        require(agreement.redeemCount < agreement.limit, "No more slots left");

        IERC20(campaignAddress).transfer(address(this), agreement.amount);

        agreement.redeemCount++;
        agreement.rewardData[msg.sender] = userData;
        agreement.rewardDistribution[campaignAddress] = agreement.redeemCount;
    }

    function awardCertificate(address campaignAddress, uint256 agreementId, address recipient, string memory _name, string memory _projectName, address currency) external {
        require(recipient != address(0), "Empty address");
        Agreement storage agreement = campaignToAgreements[campaignAddress][agreementId];
        require(msg.sender == agreement.admin, "You don't have access");
        require(agreement.rewardDistribution[recipient] != 0, "Recipient did not register for redeem");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, 1, 1, "");
        tokenIdtoCertificate[newItemId] = Certificate(_name, _projectName, agreement.amount, currency, block.timestamp);
    }
}