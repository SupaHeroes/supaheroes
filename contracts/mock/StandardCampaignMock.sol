// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ICampaign.sol";

//contract template for initiating a project
contract StandardCampaignMock is ICampaign {
    event LogPledge(address indexed by, address indexed to, uint256 amount, address currency, uint256 timestamp);
    event LogVote(address indexed by, address to, uint256 weight);
    event ChangedAdmin(address newAdmin, uint256 timestamp);
    event CampaignStopped(address indexed by, uint256 timestamp);

    struct Vest {
        uint256 claimDate;
        uint256 amount;
        IERC20 currency;
    }

    Vest[] public vests;

    ///@dev userDeposit is used to track how much each user has pledged to this campaign
    mapping(address => uint256) public userDeposit;
    uint256 public depositorsCount;
    mapping(address => bool) public votes;
    uint256 public numberOfVotes;
    uint256 public claimed;

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
        require(userDeposit[msg.sender] != 0, "You have no deposits");
        _;
    }

    //put owner in constructor to use for initializing project
    constructor(
        address _factory,
        address _currency,
        string memory _metadata,
        address _admin,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime,
        Vest[] memory _vests
    ) {
        factory = _factory;
        supportedCurrency = IERC20(_currency);
        metadata = _metadata;
        admin = _admin;
        fundingTarget = _fundTarget;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
        for(uint i = 0; i < vests.length; i++){
            Vest memory n = _vests[i];
            vests.push(n);
        }
    }

    function claimable() internal view returns (uint){
        uint total = 0;
        for(uint i = 0; i < vests.length; i++){
            if(vests[i].claimDate <= block.timestamp){
                total += vests[i].amount;
            }
        }

        return total;
    }

    function changeMetadata(string memory newMetadata) external {
        require(msg.sender == admin, "You are not the campaign admin");
       metadata = newMetadata;
    }

    function pledge(uint256 amount, address token) external override {
        require(amount > 0, "Amount cannot be 0");
        require(msg.sender != admin, "Admin cannot pledge");
        require(IERC20(token) == supportedCurrency, "Currency not supported");
        require(fundingEndTime > block.timestamp, "Funding ended");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        if(userDeposit[msg.sender] == 0){
            depositorsCount++;
        }
        userDeposit[msg.sender] += amount;
    }

    //emergency function to stop the funding (and stop the project)
    function stopCampaign() external {
        require(msg.sender == admin, "You are not the admin");
        require(fundingEndTime > block.timestamp, "campaign has already ended");
        require(isCampaignStopped == false, "campaign already stopped");
        isCampaignStopped = true;
        fundingEndTime = block.timestamp;
    }

    function voteRefund() external onlyPledgers {
        require(isCampaignStopped == false, "Campaign has already been stopped");
        votes[msg.sender] = true;
        numberOfVotes += 1;
        if(depositorsCount / 2 < numberOfVotes) {
            isCampaignStopped = true;
        }
    }

    function userBalance(address user, address erc20) external override view  returns (uint256){
        require(IERC20(erc20) == supportedCurrency, "Currency not supported");
        return userDeposit[user];
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
        require(userDeposit[msg.sender] > 0, "You have no balance left to withdraw"); // guards up front
        require(fundingEndTime > block.timestamp || isCampaignStopped, "Campaign is still running");
        userDeposit[msg.sender] -= amount; // optimistic accounting
        IERC20(supportedCurrency).transferFrom(address(this), msg.sender, amount); // transfer
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
        require(amount <= IERC20(supportedCurrency).balanceOf(address(this)), "This campaign contract doesn't have enough balance");

        if(vests.length != 0){
            require(claimable() > claimed, "Please wait for your vest date");
            IERC20(supportedCurrency).transfer(to, amount);
            claimed += amount;
            return true;
        }

        IERC20(supportedCurrency).transfer(to, amount);
        return true;
    }
}
