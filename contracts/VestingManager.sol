// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces/ICampaign.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


/* 
    Vested Campaign Strategy Contract for Supaheroes.org
        
    ███████████████████████████████████████████████████████████
    █─▄▄▄▄█▄─██─▄█▄─▄▄─██▀▄─██─█─█▄─▄▄─█▄─▄▄▀█─▄▄─█▄─▄▄─█─▄▄▄▄█
    █▄▄▄▄─██─██─███─▄▄▄██─▀─██─▄─██─▄█▀██─▄─▄█─██─██─▄█▀█▄▄▄▄─█
    ▀▄▄▄▄▄▀▀▄▄▄▄▀▀▄▄▄▀▀▀▄▄▀▄▄▀▄▀▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
    
    Manages the vesting strategy for StandardCampaignStrategy. This contract
    will allow certain amount of fund to be withdrawn by campaign owner based
    on the agreement made.
    */

    /**Supaheroes Vesting Manager */
contract VestingManager is Initializable  {

    //vesting term struct does not contain metadata, deal with this on the frontend to save gas
    uint[] public dates;
    uint[] public amounts;

    uint[] private claimedDates;

    //amount claimed by admin
    uint256 public claimed;

    //admin address
    address admin;

    //Campaign address
    ICampaign public campaign;

     /**
     * @dev Vesting manager follows EIP-1167 Minimal Proxy use this to initialize vesting manager instead of constructor
     * for more information head over to https://eips.ethereum.org/EIPS/eip-1167
     * Same matrix matching mechanism like RewardManager contract
     * 
     * @param _dates dates in array refer to RewardManager contract to see how this works
     * @param _amounts amounts in array refer to RewardManager contract to see how this works
     * @param _campaign campaign address
     */
    function initialize (uint[] memory _dates, uint[] memory _amounts, address _campaign) external initializer {
        require(_dates.length == _amounts.length, "Not same length");
        admin = msg.sender;
        campaign = ICampaign(_campaign);
        dates = _dates;
        amounts = amounts;
    }

     /**
     * @notice Check how much is claimable for admin
     */
    function claimable() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (dates[i] <= block.timestamp) {
                total += amounts[i];
            }
        }

        return total - claimed;
    }

     /**
     * @notice Pay out according to the vesting agreement
     * @param to address to send to
     * @param amount the amount of fund to payout
     */
    function payOutClaimable(address to, uint256 amount)
        external
        returns (bool success)
    {
        require(msg.sender == admin, "Admin only");
        uint256 _claimable = claimable();
        require(amount <= _claimable, "Not available yet");
        claimed += amount;
        campaign.payOut(to, amount);
        return true;
    }
}
