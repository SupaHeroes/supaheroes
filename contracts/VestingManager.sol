// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces/ICampaign.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* 
    Vested Campaign Strategy Contract for Supaheroes.org
    Author: Axel Devara
        
    ███████████████████████████████████████████████████████████
    █─▄▄▄▄█▄─██─▄█▄─▄▄─██▀▄─██─█─█▄─▄▄─█▄─▄▄▀█─▄▄─█▄─▄▄─█─▄▄▄▄█
    █▄▄▄▄─██─██─███─▄▄▄██─▀─██─▄─██─▄█▀██─▄─▄█─██─██─▄█▀█▄▄▄▄─█
    ▀▄▄▄▄▄▀▀▄▄▄▄▀▀▄▄▄▀▀▀▄▄▀▄▄▀▄▀▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
    
    Creates a vested campaign strategy, an iteration of Supaheroes's Standard Campaign Strategy(SCS).
    This strategy has pretty much the same concept as SCS but with added security for contributors.
    By having a vesting term, project owners are only able to claim funds based on the specified terms.
    This provides a feeling of trust and safety for contributors.
    */
contract VestingManager {
    ///@dev vesting term struct does not contain metadata, deal with this on the frontend to save gas
    struct Vest {
        uint256 claimDate;
        uint256 amount;
    }

    Vest[] public vests;
    uint256 public claimed;
    address admin;

    ICampaign public immutable campaign;

    constructor(
        Vest[] memory _vests,
        ICampaign _campaign,
        address _admin
    ) {

        admin = _admin;
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
        require(msg.sender == admin, "You are not the admin of the campaign");
        uint256 _claimable = claimable();
        require(amount <= _claimable);
        require(_claimable >= claimed, "Please wait for your vest date");
        campaign.payOut(to, amount);
        claimed += amount;
        return true;
    }
}
