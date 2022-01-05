// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ContributionCertificate is ERC721, Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) whitelistedManager;
    address factory;
    constructor(address _factory) ERC721("Supaheroes Contributor Certificate", "SCC"){
        factory = _factory;
    }

    function changeFactory(address newFactory) external onlyOwner {
        factory = newFactory;
    }

    function registerManager(address manager) external {
        require(msg.sender == factory);
        whitelistedManager[manager] = true;
    }

    function mint(address to) external returns(uint) {
        require(whitelistedManager[msg.sender]);
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);
        return newItemId;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://Qmdz6qQ1gkHsBuxiwmLYyM8PeeiBq9JyjbGUVN3WyQeGcW/";
    }
}