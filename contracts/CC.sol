// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ContributionCertificate is ERC721, Ownable{
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;
    string private _uriBase;

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

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_uriBase, tokenId.toString(), ".json"));
    }

    function setBaseUri(string memory uri) external onlyOwner{
        _uriBase = uri;        
    }

}