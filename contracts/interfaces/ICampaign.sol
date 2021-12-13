// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ICampaign {

    function pledge(uint256 amount,uint256 weight, address token) external;

    function payOut(address to, uint256 amount) external returns (bool);
}
