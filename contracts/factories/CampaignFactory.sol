// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* 
    CampaignFactory for Supaheroes.org
        
    ███████████████████████████████████████████████████████████
    █─▄▄▄▄█▄─██─▄█▄─▄▄─██▀▄─██─█─█▄─▄▄─█▄─▄▄▀█─▄▄─█▄─▄▄─█─▄▄▄▄█
    █▄▄▄▄─██─██─███─▄▄▄██─▀─██─▄─██─▄█▀██─▄─▄█─██─██─▄█▀█▄▄▄▄─█
    ▀▄▄▄▄▄▀▀▄▄▄▄▀▀▄▄▄▀▀▀▄▄▀▄▄▀▄▀▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
    
    A factory contract to create campaign from various strategies and also making the agreements
    for RewardManager contract. This contract is crucial to the frontend because most of the events
    for indexing will come from this contract. 
    */

contract CampaignFactory is Ownable {
    address public master;
    address public rewardMaster;
    address public vestingMaster;

    event ContractLog(uint);
    event NewCampaign(address indexed contractAddress, address indexed creator, address rewardMaster, address vestingMaster);

    using Clones for address;

    constructor(address _master, address _master2, address _master3) {
        master = _master;
        rewardMaster = _master2;
        vestingMaster = _master3;
    }

    function changeMasters(address _newMaster, address _newReward, address _newVesting) external onlyOwner {
        master = _newMaster;
        rewardMaster = _newReward;
        _newVesting = _newVesting;
        emit ContractLog(block.timestamp);
    }

    function createCampaign() external payable {
        address newAddress = master.clone();
        address reward = rewardMaster.clone();
        emit NewCampaign(newAddress, msg.sender, reward, address(0));
    }

    function createCampaignWithVesting() external payable {
        address newAddress = master.clone();
        address reward = rewardMaster.clone();
        address vest = vestingMaster.clone();
        emit NewCampaign(newAddress, msg.sender, reward, vest);
    }
}