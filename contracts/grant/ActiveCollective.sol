// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Sample matching contract, Not real implementation. Needs to decide how the whole round will work in near future.
contract ActiveCollective is Ownable {
   mapping(address => uint256) matchAmount;
   mapping(address => uint256) tokenToPoolAmt;

   function setPool(uint256 amt_) external onlyOwner {
       tokenToPoolAmt[msg.sender] += amt;
   }

   function matchFund(uint256[] contributions_, uint256[] goals_, uint256 index_, address token_) external returns(uint256 amt_) {
       uint256 total = 0;
       for(uint256 i = 0; i < contributions_.length; i++) {
           total += contributions_[i];
       }
       matchAmount[msg.sender] = contributions_[index_] * contributions_[index_] / goals_[index_] * total * tokenToPoolAmt[token_];
       return matchAmount[msg.sender];
   }
}
