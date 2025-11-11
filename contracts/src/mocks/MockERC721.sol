// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    uint256 public lastTokenId;

    constructor() ERC721("Mock", "Mock") {}

    function mint(address to) external returns (uint256 tokenId) {
        tokenId = ++lastTokenId;
        _safeMint(to, tokenId);
    }
}
