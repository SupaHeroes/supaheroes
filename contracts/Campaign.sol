// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICampaign.sol";

//contract template for initiating a project
contract Campaign is Ownable, ICampaign {
    mapping(address => uint256) public userDeposit;
    //variable for projectname

    string metadata_uri;
    //variable for projectstarter (EOA projectstarter)
    address payable treasury;
    //starttime of fundingperiod (is this necessary?)
    uint256 fundingStartTime;
    //endtime of fundingperiod
    uint256 fundingEndTime;
    //Targetamount for funding
    uint256 fundTarget;
    //current balance of the project
    bool isInitialized;

    //put owner in constructor to use for initializing project
    constructor(
        string memory _metadata,
        address payable _treasury,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime
    ) {
        treasury = _projectStarter;
        metadata_uri = _metadata;
        fundTarget = _fundTarget;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
    }

    function pledge(uint256 amount, address token) external override {
        require(amount > 0, "Amount cannot be 0");
        require(fundingEndTime > block.timestamp, "Funding ended");

        userDeposit[msg.sender] += amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    //emergency function to stop the funding (and stop the project)
    function stopProject() public onlyOwner {
        fundingEndTime = block.timestamp;
    }

    function getProjectDetails()
        public
        view
        returns (
            string memory Metadata,
            address Treasury,
            uint256 Target,
            uint256 Balance
        )
    {
        Metadata = metadata_uri;
        Treasury = treasury;
        Target = fundTarget;
        Balance = address(this).balance;
        return (Metadata, Treasury, Target, Balance);
    }

    //How to see these variables when calling function?

    //function for returning the funds
    function withdrawFunds(uint256 amount) public returns (bool success) {
        require(userDeposit[msg.sender] >= 0); // guards up front
        userDeposit[msg.sender] -= amount; // optimistic accounting
       payable(msg.sender).transfer(amount); // transfer
        return true;
    }

    function changeMetadata(string memory url) external override onlyOwner{
        metadata_uri = url;
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
