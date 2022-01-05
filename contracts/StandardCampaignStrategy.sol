// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/ICampaign.sol";
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

 /* 
    Standard Campaign Strategy Contract for Supaheroes.org
        
    ███████████████████████████████████████████████████████████
    █─▄▄▄▄█▄─██─▄█▄─▄▄─██▀▄─██─█─█▄─▄▄─█▄─▄▄▀█─▄▄─█▄─▄▄─█─▄▄▄▄█
    █▄▄▄▄─██─██─███─▄▄▄██─▀─██─▄─██─▄█▀██─▄─▄█─██─██─▄█▀█▄▄▄▄─█
    ▀▄▄▄▄▄▀▀▄▄▄▄▀▀▄▄▄▀▀▀▄▄▀▄▄▀▄▀▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
    
    Creates a standard campaign for projects that require crowdfunding. Pledgers can safely
    pledge through this smart contract or through reward manager to receive reward and voting power.
    If found to be a fraud, campaign can be stopped by 40% quorum through voting process.

    * Standard campaign strategy requires a reward manager
    * Vesting manager is optional
    * Vesting is recommended as it gives confidence to supporters
    * Metadata standard can be seen on Supaheroes docs
    */
    
/** @title Supaheroes Standard Campaign Strategy */
contract StandardCampaignStrategy is ICampaign, Initializable {
    event LogPledge(address indexed by, address indexed to, uint256 amount, address currency, uint256 timestamp);
    event LogRefund(address indexed by, uint256 amount, uint256 timestamp);
    event LogVote(uint256 indexed at, address to, uint256 weight);
    event CampaignStopped(uint256 indexed timestamp);

    //total voting weight
    uint256 public totalWeight;
    //total voted weight
    uint256 public votedWeight;

    //project admin
    address public admin;
    //the start time of crowdfunding session
    uint256 public fundingStartTime;
    //the end of crowdfunding session time
    uint256 public fundingEndTime;
    //the amount of funds to reach a goal
    uint256 public fundingTarget;
    //ipfs url to campaign information
    string public metadata;

    //put in the prefered currency for this campaign(recommended: stablecoins such as USDC/DAI)
    IERC20 public supportedCurrency;

    //is the campaign running?
    bool public isCampaignStopped = false;

    //address of the vesting manager contract
    address public vestingManager;
    //address of the reward manager contract
    address public rewardManager;

    /**
     * @dev StandardCampaignStrategy follows EIP-1167 Minimal Proxy use this to initialize StandardCampaign instead of constructor
     * for more information head over to https://eips.ethereum.org/EIPS/eip-1167
     * 
     * @param _currency sets the currency for the campaign
     * @param _metadata off-chain campaign data just like ERC721. Recommendation: host on IPFS
     * @param _fundingEndTime sets campaign end time
     * @param _fundTarget funding goal amount
     * @param _fundingStartTime when the campaign will start
     * @param _vestingManager the vesting manager. Set to address(0) if there is no vesting manager
     * @param _rewardManager the reward manager. required!
     */
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
        require(_rewardManager != address(0), "No reward manager");
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

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    /**
     * @notice Campaign owners are able to change the metadata of the campaign
     * @param newMetadata the new metadata uri
     */
    function changeMetadata(string memory newMetadata) external onlyAdmin {
        require(block.timestamp < fundingEndTime, "Campaign ended");
       metadata = newMetadata;
    }

    /**
     * @notice Pledge through this contract is basically a donation. You will not receive a reward or a voting power
     * thus is not recommended unless you choose to do so. Pledge through reward manager instead to receive reward and voting power.
     * @param amount the amount of fund
     * @param weight the voting weight (see RewardManager.sol)
     * @param token currency address
     */
    function pledge(uint256 amount, uint256 weight, address token, address from) external override {
        require(amount > 0, "Amount 0");
        require(msg.sender != admin, "Admin cannot pledge");
        require(IERC20(token) == supportedCurrency, "Currency not supported");
        require(fundingEndTime > block.timestamp, "Funding ended");

        if(msg.sender == rewardManager){
            totalWeight += weight; //re-entrancy guard
        }
        IERC20(token).transferFrom(from, address(this), amount); 
        emit LogPledge(from, address(this), amount, token, block.timestamp);      
    }

    /**
     * @notice Circuit breaker function to stop the campaign
     */
    function stopCampaign() external onlyAdmin {
        require(fundingEndTime > block.timestamp, "campaign ended");
        require(isCampaignStopped == false, "campaign stopped");
        isCampaignStopped = true;
        fundingEndTime = block.timestamp;
        emit CampaignStopped(block.timestamp);
    }

    /**
     * @notice Pledgers have the ability to vote for a refund and stop the campaign using the given ERC1155 token
     * see RewardManager.sol for more information
     * @param weight the voting weight (see rewardManager.sol)
     */
    function voteRefund(uint weight) external onlyRewardManager {
        require(isCampaignStopped == false, "Campaign stopped");
        votedWeight += weight;
        if(votedWeight  < totalWeight * 40/100) {
            isCampaignStopped = true;
        }
        emit LogVote(block.timestamp ,address(this), weight);
    }

    /**
     * @notice Call this function to unvote
     * @param weight the voting weight (see rewardManager.sol)
     */
    function unvote(uint weight) external onlyRewardManager {
        require(isCampaignStopped == false, "Campaign stopped");
        votedWeight -= weight;
    }

    /**
     * @notice Helper function to get project details
     */
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

    /**
     * @notice Once a campaign is stopped, pledgers will be able to withdraw their funds.
     * only callable through reward manager
     * @param amount the amount to withdraw
     */
    function withdrawFunds(uint256 amount, address recipient) external onlyRewardManager returns (bool success) {
        require(amount > 0, "Cannot withdraw 0");
        require(isCampaignStopped, "Campaign is still running");
        supportedCurrency.approve(msg.sender, amount);
        totalWeight -= amount; //re-entrancy guard
        supportedCurrency.transferFrom(address(this), recipient, amount); // transfer from campaign to user
        emit LogRefund(recipient, amount, block.timestamp);
        return true;
    }


    /**
     * @notice Receive the crowdfund after campaign ends. If vested, this function can only be called from vesting manager contract
     * @param to transfer to address
     * @param amount the amount to transfer
     */
    function payOut(address to,uint256 amount) external override onlyAdmin returns (bool success) {
        require(vestingManager == address(0) || msg.sender == vestingManager, "Use payOutClaimable");
        require(amount > 0, "0 amount");
        require(fundingEndTime < block.timestamp, "Campaign is still running");
        require(isCampaignStopped == false, "Campaign has been stopped");

        supportedCurrency.approve(msg.sender, amount);
        supportedCurrency.transfer(to, amount);
        return true;
    }
}
