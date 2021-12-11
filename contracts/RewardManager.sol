// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./strategies/StandardCampaignStrategy.sol";

/* 
    Reward Manager for Supaheroes.org
    Author: Axel Devara
        
    ███████████████████████████████████████████████████████████
    █─▄▄▄▄█▄─██─▄█▄─▄▄─██▀▄─██─█─█▄─▄▄─█▄─▄▄▀█─▄▄─█▄─▄▄─█─▄▄▄▄█
    █▄▄▄▄─██─██─███─▄▄▄██─▀─██─▄─██─▄█▀██─▄─▄█─██─██─▄█▀█▄▄▄▄─█
    ▀▄▄▄▄▄▀▀▄▄▄▄▀▀▄▄▄▀▀▀▄▄▀▄▄▀▄▀▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
    
    Creates a Supahero Contributor Certificate (SCC) as a proof of contribution. The certificate 
    is meant to be platform specific which in this case, Supaheroes. For now, certificate is awarded manually
    by campaign admin. Feel free to fork/PR this contract.
    */
contract RewardManager is ERC1155 {    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address public campaign;
    address public admin;

    uint256 internal certificateId;

    constructor(address _campaign, address _admin, string memory _uri, uint256[] memory quantities) ERC1155(_uri) {
        campaign = _campaign;
        admin = _admin;
        
        for(uint i = 0; i < quantities.length; i++){
            _mint(address(this), i, quantities[i], "");
        }
        certificateId = quantities.length + 1;
    }

    function setUri(string memory _uri) external {
        require(msg.sender == admin);
        _setURI(_uri);
    }

    function redeemForVote(uint amount, uint id) external {
        StandardCampaignStrategy(campaign).voteRefund(amount);
        safeTransferFrom(msg.sender, address(this), id, amount, "");
    }

    function unVote(uint amount, uint id) external {
        StandardCampaignStrategy(campaign).unvote(amount);
        safeTransferFrom(address(this), msg.sender, id, amount, "");
    }

    function redeem(uint amount, uint id) external { 
        StandardCampaignStrategy(campaign).withdrawFunds(amount);
        safeTransferFrom(msg.sender, address(this), id, amount, "");
    }

    function approveReward(uint amount, uint id) external { 
        StandardCampaignStrategy(campaign).withdrawFunds(amount);
        _burn(msg.sender, id, amount);
        _mint(msg.sender, certificateId, 1, "");
    }

    function pledgeForReward(uint amount, uint id, address token) external {
        require(this.balanceOf(address(this), id) > 0);
        StandardCampaignStrategy(campaign).pledge(amount, token);
        safeTransferFrom(address(this), msg.sender, id, 1, "");
    }
}