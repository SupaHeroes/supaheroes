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

    This contract follows EIP-1167 for more information see https://eips.ethereum.org/EIPS/eip-1167
    */

/**Supaheroes Campaign Factory */
contract CampaignFactory is Ownable {

    //StandardCampaignStrategy master contract address
    address public master;
    //rewardManager master contract address
    address public rewardMaster;
    //vestingManager master contract address
    address public vestingMaster;
    //cc address
    address public cc;

    event ContractLog(uint timestamp, address campaignMaster, address rewardMaster, address vestingMaster);
    event NewCampaign(address indexed contractAddress, address indexed creator, address rewardMaster, address vestingMaster);

    //clones library from OpenZeppelin
    using Clones for address;

    /**
    Sets master contract addresses for each components. A supaheroes campaign consists of 3 components:
        - Strategy contract
        - Reward manager contract
        - Vesting manager contract(Optional) 
    
    @param _master Campaign strategy contract
    @param _master2 Reward manager contract
    @param _master3 Vesting manager contract
    */
    constructor(address _master, address _master2, address _master3, address _cc) {
        master = _master;
        rewardMaster = _master2;
        vestingMaster = _master3;
        cc = _cc;
    }

    /**
    @notice Changes the master addresses
    @dev Calling this contract should be done through multisig/gnosis
    @param _newMaster Campaign strategy contract
    @param _newReward Reward manager contract
    @param _newVesting Vesting manager contract
     */
    function changeMasters(address _newMaster, address _newReward, address _newVesting) external onlyOwner {
        master = _newMaster;
        rewardMaster = _newReward;
        vestingMaster = _newVesting;
        emit ContractLog(block.timestamp, master, rewardMaster, vestingMaster);
    }

    /**
    @notice Changes the master addresses
    @dev Calling this contract should be done through multisig/gnosis
    @param _cc Campaign strategy contract
     */
    function changeCC(address _cc) external onlyOwner {
        cc = _cc;
    }

    /**
    @notice Creates a campaign strategy contract + reward manager contract
    @dev Make sure to initialize each contracts before taken by other people. Important! 
     */
    function createCampaign() external payable {
        address newAddress = master.clone();
        address reward = rewardMaster.clone();

        cc.call(
            abi.encodeWithSignature("registerManager(address)", reward)
        );

        emit NewCampaign(newAddress, msg.sender, reward, address(0));
    }

    /**
    @notice Creates a campaign strategy contract + reward manager contract + vesting manager contract
    @dev Make sure to initialize each contracts before taken by other people. Important! 
     */
    function createCampaignWithVesting() external payable {
        address newAddress = master.clone();
        address reward = rewardMaster.clone();
        address vest = vestingMaster.clone();

        cc.call(
            abi.encodeWithSignature("registerManager(address)", reward)
        );

        emit NewCampaign(newAddress, msg.sender, reward, vest);
    }
}