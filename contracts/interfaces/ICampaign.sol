// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ICampaign {
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    function pledge(uint256 amount, address token) external;

    function payOut(uint256 amount) external returns (uint256);

    function changeMetadata(string memory url) external;

    function changeTreasuryAddress(address payable newTreasury) external;
}
