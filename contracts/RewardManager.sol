// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./strategies/StandardCampaignStrategy.sol";
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

/* 
    Reward Manager for Supaheroes.org
        
    ███████████████████████████████████████████████████████████
    █─▄▄▄▄█▄─██─▄█▄─▄▄─██▀▄─██─█─█▄─▄▄─█▄─▄▄▀█─▄▄─█▄─▄▄─█─▄▄▄▄█
    █▄▄▄▄─██─██─███─▄▄▄██─▀─██─▄─██─▄█▀██─▄─▄█─██─██─▄█▀█▄▄▄▄─█
    ▀▄▄▄▄▄▀▀▄▄▄▄▀▀▄▄▄▀▀▀▄▄▀▄▄▀▄▀▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
    
    Creates a Supahero Contributor Certificate (SCC) as a proof of contribution. The certificate 
    is meant to be platform specific which in this case, Supaheroes. Call functions here to
    interact with rewards.

    * Upon pledging a project users will receive a ERC1155 receipt token based on how much they pledge
    * Receipt tokens have voting powers based on their tiers to stop a campaign incase found to be a fraud
    * Once rewards/whatever agreements have been fulfilled, users can redeem the receipt
    * Redeeming the receipt will burn the receipt and replace it with a SCC
    */

    /**Supaheroes Reward Manager */
contract RewardManager is ERC1155, Initializable {  
    //campaign address
    StandardCampaignStrategy public campaign;

    //campaign admin
    address public admin;

    //How much each token type is worth based on tiers set by campaign admin
    mapping(uint => uint) idsToTiers;

    //token id for certificate this is important for ERC1155 Uri
    uint256 internal certificateId;

    //project name string for certificate purpose
    string public projectName;

    //record of user's pledge amount
    mapping(address => uint256) userPledgedAmount;

    //on-chain certificate data when you redeem
    struct Certificate {
        string projectName;
        string donatorName;
        address donatorAddress;
        uint256 time;
        uint256 amount;
        address tokenAddress;
    }

    //mapping certificate ownership
    mapping(address => Certificate) public certificateOwner;

    //mapping to record how much token each user used for voting
    mapping(address => uint256) internal votedAmount;

    constructor() ERC1155("") {
       
    }

    /**
     * @dev Reward manager follows EIP-1167 Minimal Proxy use this to initialize reward manager instead of constructor
     * for more information head over to https://eips.ethereum.org/EIPS/eip-1167
     * 
     * @param _uri sets the token uri for ERC1155. Make sure _uri follows https://eips.ethereum.org/EIPS/eip-1155
     * @param quantities sets how many the contract should mint for each token id. This contract relies on array length to match quantity to token id
     * e.g. [100 , 200 , 100 , 0] will make the contract mint 100 tokens for token id 0, 200 tokens for token id 1, and so on.
     * @param tiers sets how much each token id is worth. Like quantities, array length matches tiers to token id.
     * e.g. [1000, 2000, 3000] means to acquire token id 0, user needs to pay 1000n (n means whatever currency was set in the campaign).
     */
    function initialize(address _campaign, string memory _uri, uint256[] memory quantities, uint256[] memory tiers, string memory _projectName) external initializer {
        require(quantities.length == tiers.length, "Length difference");
        campaign = StandardCampaignStrategy(_campaign);
        projectName = _projectName;
        admin = msg.sender;
        
        for(uint i = 0; i < quantities.length; i++){
            _mint(address(this), i, quantities[i], "");
            idsToTiers[i] = tiers[i];
        }

        //certificate id will always be quantities length + 1 make sure the uri supports this
        certificateId = quantities.length + 1;

        _setURI(_uri);
    }

    //A modifier to block admin from calling his/her own function
    modifier notAdmin(){
        require(msg.sender != admin);
        _;
    }

     /**
     * @notice Each token id has voting power based on tiers. Refer to idsToTiers variable which was set during initialize()
     * 
     * @param id the ERC1155 token id that will be used to vote
     */
    function vote(uint id) external notAdmin {
        votedAmount[msg.sender] += 1;
        campaign.voteRefund(idsToTiers[id]);
        safeTransferFrom(msg.sender, address(this), id, idsToTiers[id], "");
    }

    /**
     * @notice Users are able to unvote. Unvoting will return the user's receipt token
     * 
     * @param id the ERC1155 token id that will be used to unvote
     */
    function unVote(uint id) external notAdmin {
        require(votedAmount[msg.sender] > 0, "You have not voted");
        votedAmount[msg.sender] -= 1;
        campaign.unvote(idsToTiers[id]);
        safeTransferFrom(address(this), msg.sender, id, 1, "");
    }

    /**
     * @notice Users are able to refund in case the quorum has decided to suspend the campaign
     * if the receipt is not from the original owner, the refund value is based on tiers
     * 
     * @param id the ERC1155 token id that will be sent back to this contract
     * @param amount the amount to refund
     */
    function refund(uint amount, uint id) external notAdmin { 
        require(amount >= idsToTiers[id],  "Wrong receipt");
        //check if user is the original pledger or not
        if(userPledgedAmount[msg.sender] == 0 && this.balanceOf(msg.sender, id) > 0){
            campaign.withdrawFunds(idsToTiers[id]);
        } else {
            require(userPledgedAmount[msg.sender] >= amount, "Wrong amount");
            campaign.withdrawFunds(amount);
        }        
        safeTransferFrom(msg.sender, address(this), id, 1, "");
    }

    /**
     * @notice Once reward has been received, users can approve and redeem their receipt token for certificate
     * if the sender is not the original pledger, the certificate's amount param will be based the the receipt's tier
     * 
     * @param id the ERC1155 token id that will be burned
     * @param name the name of the sender for certificate
     */
    function approveReward(uint id, string memory name) external notAdmin { 
        //check if the user is the original pledger
        if(userPledgedAmount[msg.sender] == 0 && this.balanceOf(msg.sender, id) > 0) {
            certificateOwner[msg.sender] = Certificate(projectName, name, msg.sender, block.timestamp, idsToTiers[id], address(campaign.supportedCurrency()));
        } else {
            certificateOwner[msg.sender] = Certificate(projectName, name, msg.sender, block.timestamp, userPledgedAmount[msg.sender], address(campaign.supportedCurrency()));
        }
        _burn(msg.sender, id, 1);
        _mint(msg.sender, certificateId, 1, "");
    }

    /**
     * @param id the ERC1155 token id that is desired
     * @param amount the amount to pledge in specified token currency
     * @param token currency address
     */
    function pledgeForReward(uint amount, uint id, address token) external notAdmin {
        require(this.balanceOf(msg.sender, id) == 0, "You already pledged this tier");
        require(this.balanceOf(address(this), id) > 0);
        require(amount >= idsToTiers[id]);
        campaign.pledge(amount, idsToTiers[id], token);
        userPledgedAmount[msg.sender] += amount;
        safeTransferFrom(address(this), msg.sender, id, 1, "");
    }
}