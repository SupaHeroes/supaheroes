// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IStrategy {
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address user, address erc20) external view returns (uint256);

    function pledge(uint256 amount, address token) external;

    function payOut(uint256 amount) external returns (uint256);

    function changeTreasuryAddress(address payable newTreasury) external;
}
