// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ICampaign {
    /// @notice Balance per ERC-20 token per account in shares.
    function userBalance(address user, address erc20) external view returns (uint256);

    function pledge(uint256 amount, address token) external;

    function payOut(address to, uint256 amount) external returns (bool);

    function changeAdmin(address newAdmin) external;
}
