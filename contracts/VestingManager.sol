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
contract VestingManager is Initializable  {
    ///@dev vesting term struct does not contain metadata, deal with this on the frontend to save gas
    struct Vest {
        uint256 claimDate;
        uint256 amount;
    }

    Vest[] public vests;
    uint256 public claimed;
    address admin;

    ICampaign public campaign;

    function initialize (Vest[] memory _vests, ICampaign _campaign) external initializer {
        admin = msg.sender;
        campaign = _campaign;

        for (uint256 i = 0; i < vests.length; i++) {
            Vest memory n = _vests[i];
            vests.push(n);
        }

    }

    ///@notice Check how much is claimable
    function claimable() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < vests.length; i++) {
            if (vests[i].claimDate <= block.timestamp) {
                total += vests[i].amount;
            }
        }
        return total;
    }

    ///@dev Use this for payOut instead
    function payOutClaimable(address to, uint256 amount)
        external
        returns (bool success)
    {
        require(msg.sender == admin, "Admin only");
        uint256 _claimable = claimable();
        require(amount <= _claimable);
        require(_claimable >= claimed, "No claimable");
        campaign.payOut(to, amount);
        claimed += amount;
        return true;
    }
}
