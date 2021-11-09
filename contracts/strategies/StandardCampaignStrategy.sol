// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStrategy.sol";

//contract template for initiating a project
contract StandardCampaignStrategy is Ownable, IStrategy {
    mapping(address => uint256) public userDeposit;
    //@notice project metadata can be hosted on IPFS or centralized storages.
    address payable public treasury;
    //@notice the start time of crowdfunding session
    uint256 public fundingStartTime;
    //@notice the end of crowdfunding session time
    uint256 public fundingEndTime;
    //@notice the amount of funds to reach a goal
    uint256 public fundTarget;

    IERC20 public supportedCurrency;

    //put owner in constructor to use for initializing project
    constructor(
        address payable _treasury,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime
    ) {
        treasury = _treasury;
        fundTarget = _fundTarget;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
    }

    function pledge(uint256 amount, address token) external override {
        require(amount > 0, "Amount cannot be 0");
        require(IERC20(token) == supportedCurrency);
        require(fundingEndTime > block.timestamp, "Funding ended");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        userDeposit[msg.sender] += amount;
    }

    //emergency function to stop the funding (and stop the project)
    function stopProject() public onlyOwner {
        fundingEndTime = block.timestamp;
    }

    function balanceOf(address user, address erc20) external override view returns (uint256){
        require(IERC20(erc20) == supportedCurrency);
        return userDeposit[msg.sender];
    }


    function getProjectDetails()
        public
        view
        returns (
            
            address Treasury,
            uint256 Target,
            uint256 Balance
        )
    {
        
        Treasury = treasury;
        Target = fundTarget;
        Balance = address(this).balance;
        return (Treasury, Target, Balance);
    }

    //function for returning the funds
    function withdrawFunds(uint256 amount) public returns (bool success) {
        require(userDeposit[msg.sender] >= 0); // guards up front
        userDeposit[msg.sender] -= amount; // optimistic accounting
        IERC20(supportedCurrency).transferFrom(address(this), msg.sender, amount); // transfer
        return true;
    }

    function changeTreasuryAddress(address payable newTreasury) external override onlyOwner{
        treasury = newTreasury;
    }

    function payOut(uint256 amount) external override returns (uint success) {
        require(msg.sender == treasury);
        require(fundingEndTime < block.timestamp);
        require(amount >= address(this).balance);

        treasury.transfer(amount);
        return amount;
    }
}
