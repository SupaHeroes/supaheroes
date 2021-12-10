// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/ICampaign.sol";

 /* 
    Standard Campaign Strategy Contract for Supaheroes.org
    Author: Axel Devara
        
    ███████████████████████████████████████████████████████████
    █─▄▄▄▄█▄─██─▄█▄─▄▄─██▀▄─██─█─█▄─▄▄─█▄─▄▄▀█─▄▄─█▄─▄▄─█─▄▄▄▄█
    █▄▄▄▄─██─██─███─▄▄▄██─▀─██─▄─██─▄█▀██─▄─▄█─██─██─▄█▀█▄▄▄▄─█
    ▀▄▄▄▄▄▀▀▄▄▄▄▀▀▄▄▄▀▀▀▄▄▀▄▄▀▄▀▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
    
    Creates a standard campaign strategy where pledgers receive ERC20 tokens (.fund token) based on their contribution.
    This token will be used for many things such as trading, voting, and redeem for SCC NFT after the campaign ends.
    If the campaign turns out to be a scam, users can stake their fund. token as a vote to stop the project from continuing.
    If there are 40% out of totalSupply() .fund token staked, the campaign will stop and users will be able to redeem for their first pledged currency.  
    */
contract StandardCampaignStrategy is ICampaign, ERC20 {
    event LogPledge(address indexed by, address indexed to, uint256 amount, address currency, uint256 timestamp);
    event LogVote(address indexed by, address to, uint256 weight);
    event ChangedAdmin(address newAdmin, uint256 timestamp);
    event CampaignStopped(address indexed by, uint256 timestamp);

    mapping(address => uint) public stakes;
    uint256 totalStaked;

    ///@notice this keeps track of the origin factory which helps users to asses the legitimacy 
    ///of this specific campaign.
    address public immutable factory;
    ///@notice project metadata can be hosted on IPFS or centralized storages.
    address public admin;
    ///@notice the start time of crowdfunding session
    uint256 public fundingStartTime;
    ///@notice the end of crowdfunding session time
    uint256 public fundingEndTime;
    ///@notice the amount of funds to reach a goal
    uint256 public fundingTarget;
    ///@notice ipfs url to campaign information
    string public metadata;

    ///@notice put in the prefered currency for this campaign(recommended: stablecoins such as USDC/DAI)
    IERC20 public immutable supportedCurrency;

    bool public isCampaignStopped = false;

    modifier onlyPledgers {
        require(this.balanceOf(msg.sender) > 0);
        _;
    }

    constructor(
        string memory _tokenSymbol,
        address _factory,
        address _currency,
        string memory _metadata,
        address _admin,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime
    ) ERC20(_tokenSymbol, string(abi.encodePacked("fund.", _tokenSymbol))) {
        require(_factory != address(0), "Unknown factory");
        require(_fundTarget > 0, "Fund target cannot be 0");
        require(_currency != address(0), "Needs to specify currency");
        require(block.timestamp < _fundingStartTime, "Campaign can't start before this timestamp");
        require(_fundingStartTime < _fundingEndTime, "Campaign ends before start date");
        factory = _factory;
        supportedCurrency = IERC20(_currency);
        metadata = _metadata;
        admin = _admin;
        fundingTarget = _fundTarget;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
    }

    function changeMetadata(string memory newMetadata) external {
        require(msg.sender == admin, "You are not the campaign admin");
        require(block.timestamp < fundingEndTime, "Campaign has already ended");
       metadata = newMetadata;
    }

    function pledge(uint256 amount, address token) external override {
        require(amount > 0, "Amount cannot be 0");
        require(msg.sender != admin, "Admin cannot pledge");
        require(IERC20(token) == supportedCurrency, "Currency not supported");
        require(fundingEndTime > block.timestamp, "Funding ended");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        _mint(msg.sender, amount);
    }

    //emergency function to stop the funding (and stop the project)
    function stopCampaign() external {
        require(msg.sender == admin, "You are not the admin");
        require(fundingEndTime > block.timestamp, "campaign has already ended");
        require(isCampaignStopped == false, "campaign already stopped");
        isCampaignStopped = true;
        fundingEndTime = block.timestamp;
    }

    function voteRefund(uint amount) external onlyPledgers {
        require(isCampaignStopped == false, "Campaign has already been stopped");
        this.transfer(address(this), amount);
        stakes[msg.sender] = amount;
        totalStaked += amount;
        if(totalStaked * 40/100 < this.totalSupply()) {
            isCampaignStopped = true;
        }
    }

    function unstake(uint amount) external {
        require(stakes[msg.sender] > 0, "You have no stakes");
        totalStaked -= amount;
        stakes[msg.sender] -= amount;
        this.transfer(msg.sender, amount);
    }

    function getProjectDetails()
        public
        view
        returns (           
            address _admin,
            uint256 _target,
            string memory _metadata,
            uint256 _balance,
            uint256 _fundingEndTime,
            uint256 _fundingStartTime
        )
    {
        return (admin, fundingTarget, metadata, address(this).balance, fundingEndTime, fundingStartTime);
    }

    //function for returning the funds
    function withdrawFunds(uint256 amount) public returns (bool success) {
        require(this.balanceOf(msg.sender) <= amount, "Not enough campaign token balance");
        require(isCampaignStopped, "Campaign is still running");
        this.transferFrom(msg.sender, address(this), amount); // transfer from user to campaign
        supportedCurrency.transferFrom(address(this), msg.sender, amount); // transfer from campaign to user
        return true;
    }

    function changeAdmin(address newAdmin) external override {
        require(msg.sender == admin);
        admin = newAdmin;
    }

    function payOut(address to,uint256 amount) external override returns (bool success) {
        require(msg.sender == admin, "You are not the admin of the campaign");
        require(amount > 0, "Do not put 0 in amount");
        require(fundingEndTime < block.timestamp, "Crowdfunding campaign is still running");
        require(isCampaignStopped == false, "Campaign has been stopped");
        require(amount <= supportedCurrency.balanceOf(address(this)), "This campaign contract doesn't have that much balance");

        supportedCurrency.transfer(to, amount);
        return true;
    }
}
