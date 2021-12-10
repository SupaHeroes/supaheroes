// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./StandardCampaignStrategy.sol";
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
contract VestedCampaignStrategy is StandardCampaignStrategy {
    ///@dev vesting term struct does not contain metadata, deal with this on the frontend to save gas
    struct Vest {
        uint256 claimDate;
        uint256 amount;
    }

    Vest[] public vests;
    bool public isVested;
    uint256 public claimed;

    constructor(
        string memory _tokenSymbol,
        address _factory,
        address _currency,
        string memory _metadata,
        address _admin,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime,
        Vest[] memory _vests
    ) StandardCampaignStrategy(_tokenSymbol, _factory, _currency, _metadata, _admin, _fundingEndTime, _fundTarget, _fundingStartTime) {
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

    ///@dev Disabled the original payOut method instead of overriding to avoid confusion
    function payOut(address to, uint256 amount) external override returns(bool success) {
        require(!isVested, "Use payOutClaimable() function");
        return false;
    }

    ///@dev Use this for payOut instead
    function payOutClaimable(address to, uint256 amount)
        external
        returns (bool success)
    {
        require(msg.sender == admin, "You are not the admin of the campaign");
        require(claimable() >= claimed, "Please wait for your vest date");
        require(amount > 0, "Do not put 0 in amount");
        require(
            fundingEndTime < block.timestamp,
            "Crowdfunding campaign is still running"
        );
        require(isCampaignStopped == false, "Campaign has been stopped");
        require(
            amount <= supportedCurrency.balanceOf(address(this)),
            "This campaign contract doesn't have enough balance"
        );
        supportedCurrency.transfer(to, amount);
        claimed += amount;
        return true;
    }
}
