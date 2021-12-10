// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ICampaign {

    function pledge(uint256 amount, address token) external;

    function payOut(address to, uint256 amount) external returns (bool);

    function changeAdmin(address newAdmin) external;
}
