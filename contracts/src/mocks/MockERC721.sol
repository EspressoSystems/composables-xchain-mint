// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    mapping(address => bool) public blacklist;
    uint256 public lastTokenId;

    error Blacklisted();

    constructor(address blacklisted) ERC721("Mock", "Mock") {
        blacklist[blacklisted] = true;
    }

    modifier notBlacklisted(address account) {
        if (blacklist[account]) revert Blacklisted();
        _;
    }

    function mint(address to) external notBlacklisted(to) returns (uint256 tokenId) {
        tokenId = lastTokenId++;
        _safeMint(to, tokenId);
    }
}
