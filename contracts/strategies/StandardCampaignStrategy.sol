// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../interfaces/ICampaign.sol";
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

 /* 
    Standard Campaign Strategy Contract for Supaheroes.org
        
    ███████████████████████████████████████████████████████████
    █─▄▄▄▄█▄─██─▄█▄─▄▄─██▀▄─██─█─█▄─▄▄─█▄─▄▄▀█─▄▄─█▄─▄▄─█─▄▄▄▄█
    █▄▄▄▄─██─██─███─▄▄▄██─▀─██─▄─██─▄█▀██─▄─▄█─██─██─▄█▀█▄▄▄▄─█
    ▀▄▄▄▄▄▀▀▄▄▄▄▀▀▄▄▄▀▀▀▄▄▀▄▄▀▄▀▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
    
    Creates a standard campaign strategy where pledgers receive ERC20 tokens (.fund token) based on their contribution.
    This token will be used for many things such as trading, voting, and redeem for SCC NFT after the campaign ends.
    If the campaign turns out to be a scam, users can stake their fund. token as a vote to stop the project from continuing.
    If there are 40% out of totalSupply() .fund token staked, the campaign will stop and users will be able to redeem for their first pledged currency.  
    */
    
contract StandardCampaignStrategy is ICampaign, Initializable {
    event LogPledge(address indexed by, address indexed to, uint256 amount, address currency, uint256 timestamp);
    event LogVote(address indexed by, address to, uint256 weight);
    event ChangedAdmin(address newAdmin, uint256 timestamp);
    event CampaignStopped(address indexed by, uint256 timestamp);

    uint256 public totalWeight;
    uint256 public votedWeight;

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
    IERC20 public supportedCurrency;

    bool public isCampaignStopped = false;

    address public vestingManager;
    address public rewardManager;

    function initialize(
        address _currency,
        string memory _metadata,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime,
        address _vestingManager,
        address _rewardManager
    ) public initializer {
        require(_fundTarget > 0, "Fund target 0");
        require(_currency != address(0), "No currency");
        require(block.timestamp < _fundingStartTime, "start before this timestamp");
        require(_fundingStartTime < _fundingEndTime, "ends before start date");
        supportedCurrency = IERC20(_currency);
        metadata = _metadata;
        admin = msg.sender;
        fundingTarget = _fundTarget;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
        vestingManager = _vestingManager;
        rewardManager = _rewardManager;
    }

    modifier onlyRewardManager() {
        require(rewardManager != address(0));
        require(msg.sender == rewardManager);
        _;
    }

    function changeMetadata(string memory newMetadata) external {
        require(msg.sender == admin, "Only admin");
        require(block.timestamp < fundingEndTime, "Campaign ended");
       metadata = newMetadata;
    }

    function pledge(uint256 amount, address token) external override {
        require(amount > 0, "Amount 0");
        require(msg.sender != admin, "Admin cannot pledge");
        require(IERC20(token) == supportedCurrency, "Currency not supported");
        require(fundingEndTime > block.timestamp, "Funding ended");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        totalWeight += amount;        
    }

    //emergency function to stop the funding (and stop the project)
    function stopCampaign() external {
        require(msg.sender == admin, "Not admin");
        require(fundingEndTime > block.timestamp, "campaign ended");
        require(isCampaignStopped == false, "campaign stopped");
        isCampaignStopped = true;
        fundingEndTime = block.timestamp;
    }

    function voteRefund(uint weight) external onlyRewardManager {
        require(isCampaignStopped == false, "Campaign stopped");
        // this.transfer(address(this), amount);
        votedWeight += weight;
        if(votedWeight  < totalWeight * 40/100) {
            isCampaignStopped = true;
        }
    }

    function unvote(uint weight) external onlyRewardManager {
        require(isCampaignStopped == false, "Campaign stopped");
        votedWeight -= weight;
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
    function withdrawFunds(uint256 amount) external onlyRewardManager returns (bool success) {
        require(amount > 0, "Cannot withdraw 0");
        require(isCampaignStopped, "Campaign is still running");
        totalWeight -= amount;
        supportedCurrency.transferFrom(address(this), msg.sender, amount); // transfer from campaign to user
        return true;
    }

    function changeAdmin(address newAdmin) external override {
        require(msg.sender == admin);
        admin = newAdmin;
    }

    function payOut(address to,uint256 amount) external override returns (bool success) {
        require(vestingManager == address(0) || msg.sender == vestingManager, "Use payOutClaimable");
        require(msg.sender == admin, "You are not the admin of the campaign");
        require(amount > 0, "0 amount");
        require(fundingEndTime < block.timestamp, "Campaign is still running");
        require(isCampaignStopped == false, "Campaign has been stopped");
        require(amount <= supportedCurrency.balanceOf(address(this)), "Not enough balance");

        supportedCurrency.transfer(to, amount);
        return true;
    }
}
