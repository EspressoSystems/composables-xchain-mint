pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title EspNFT — ERC721 with role-restricted minting, base-IPFS tokenImageUri generation and onchain metadata.
 * @notice Minting restricted to MINTER_ROLE.
 * @dev Uses OpenZeppelin ERC721 + AccessControl
 */
contract EspNFT is ERC721, AccessControl {
    using Strings for uint256;
    using Strings for string;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public lastTokenId;
    string private baseImageURI;
    string private chainName;
    mapping(uint256 tokenId => uint256 machineType) public machineTypes;

    event TokenMinted(address indexed to, uint256 indexed tokenId, uint256 machineType);
    event BaseImageUriChanged(string oldBaseImageUri, string newBaseImageUri);

    error UriQueryNotExist(uint256 tokenId);
    error CallerIsNotAnTokenOwnerOrApproved(address caller, uint256 tokenId);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseImageUri,
        string memory chain,
        address espHypErc20
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, espHypErc20);

        baseImageURI = baseImageUri;
        chainName = chain;
    }

    /**
     * @notice Mint token on 'to' address
     * @dev Only accounts with MINTER_ROLE can call. tokenId must not exist.
     */
    function safeMint(address to) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = lastTokenId++;
        uint256 machineType = _generateMachineType(tokenId);

        _safeMint(to, tokenId);
        emit TokenMinted(to, tokenId, machineType);
    }

    /**
     * @notice Set base image URI (e.g. "ipfs://Qm.../") — imageUrl will be baseImageURI + machineTheme + .png
     * @dev Only DEFAULT_ADMIN_ROLE can change
     */
    function setBaseImageUri(string calldata newImageURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory old = baseImageURI;
        baseImageURI = newImageURI;
        emit BaseImageUriChanged(old, baseImageURI);
    }

    /**
     * @notice tokenURI returns composed metadata json NFT.
     * ===========================
     * tokenURI management and generation
     * ===========================
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert UriQueryNotExist(tokenId);

        if (bytes(baseImageURI).length == 0) {
            return string(abi.encodePacked(tokenId.toString()));
        }

        string memory machineTheme = _getMachineTheme(tokenId);

        // Image URL example "ipfs://img123abc/Future.png"
        string memory imageURL = string(abi.encodePacked(baseImageURI, machineTheme, ".png"));

        // Compose the metadata JSON
        string memory json = string(
            abi.encodePacked(
                "{",
                '"name": "',
                chainName,
                " Espresso Machine #",
                tokenId.toString(),
                '",',
                '"description": "Mint across chains without bridging. Powered by Espresso, ApeChain, and RARI Chain to showcase seamless, composable NFT minting.",',
                '"image": "',
                imageURL,
                '",',
                '"attributes": [',
                '{ "trait_type": "Theme", "value": "',
                machineTheme,
                '" }',
                "]",
                "}"
            )
        );

        // Encode JSON to base64 for full ERC721 compliance
        return string(abi.encodePacked("data:application/json;utf8,", json));
    }

    // @notice Burn token (owner or approved)
    function burn(uint256 tokenId) external {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert CallerIsNotAnTokenOwnerOrApproved(msg.sender, tokenId);
        _burn(tokenId);
    }

    function _generateMachineType(uint256 tokenId) internal returns (uint256) {
        uint8 machineType = uint8((uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId))) % 5) + 1);
        machineTypes[tokenId] = machineType;
        return machineType;
    }

    function _getMachineTheme(uint256 tokenId) internal view returns (string memory) {
        uint256 machineType = machineTypes[tokenId];
        if (machineType == 1) {
            return "Future";
        } else if (machineType == 2) {
            return "Classic";
        } else if (machineType == 3) {
            return "Industrial";
        } else if (machineType == 4) {
            return "Organic";
        } else {
            return "Mythic";
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

//TODO write deployment scripts for 2 chains with different image URLs, write tests.
