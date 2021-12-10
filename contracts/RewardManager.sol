// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/ICampaign.sol";

contract RewardManager is ERC721, Ownable {    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;


    mapping(address => bool) whitelistedCaller;
    mapping(address => bool) whitelistedCampaign;
    mapping(address => Agreement[]) campaignToAgreements;

    struct Agreement {
        uint256 amount;
        uint256 limit;
        uint256 redeemCount;
        address admin;
        mapping(address => uint) rewardDistribution;
        mapping(address => string) rewardData;
        string metadata;
    }

    constructor() ERC721("Supahero Contributor Certificate", "SCC") {

    }

    function whitelistCaller(address caller) external onlyOwner {
        whitelistedCaller[caller] = true;
    }

    function whitelistCampaign(ICampaign campaignAddress) external {
        whitelistedCampaign[address(campaignAddress)] = true;
    }

    function createAgreement(uint _amt, uint _limit, string memory _metadata, address _campaign, address _admin) external {
        require(whitelistedCaller[msg.sender]);
        campaignToAgreements[_campaign].push(Agreement(_amt, _limit, 0, _admin,0 , 0, _metadata));
    }

    function registerForRedeem(address campaignAddress, uint256 agreementId, string memory userData) external {
        require(campaignAddress != address(0));
        require(whitelistedCampaign[campaignAddress]);
        require(campaignToAgreements[campaignAddress].length > agreementId);
        Agreement storage agreement = campaignToAgreements[campaignAddress][agreementId];
        require(msg.sender != agreement.admin);
        require(agreement.redeemCount < agreement.limit);

        IERC20(campaignAddress).transfer(address(this), agreement.amount);

        agreement.redeemCount++;
        agreement.rewardData[msg.sender] = userData;
        agreement.rewardDistribution[campaignAddress] = agreement.redeemCount;
    }

    function awardCertificate(address campaignAddress, uint256 agreementId, address recipient) external {
        require(recipient != address(0));
        Agreement storage agreement = campaignToAgreements[campaignAddress][agreementId];
        require(msg.sender == agreement.admin);
        require(agreement.rewardDistribution[recipient] != 0);

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
    }
}