// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title EspNFT — ERC721 with role-restricted minting, base-IPFS tokenImageUri generation and onchain metadata.
 * @notice Minting restricted to MINTER_ROLE.
 * @dev Uses OpenZeppelin ERC721 + AccessControl
 */
contract EspNFT is ERC721, AccessControl, IERC2981 {
    using Strings for uint256;
    using Strings for string;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // The NFT sale price in Wei
    uint256 public nftSalePrice;
    address payable public treasury;
    address public royaltyReceiver;
    uint96 public royaltyFeeNumerator;
    uint96 public constant DEFAULT_ROYALTY_BPS = 500; // 5%

    uint256 public lastTokenId;
    string private baseImageURI;
    string private chainName;
    mapping(uint256 tokenId => uint256 machineType) public machineTypes;

    event TokenMinted(address indexed to, uint256 indexed tokenId, uint256 machineType);
    event BaseImageUriChanged(string oldBaseImageUri, string newBaseImageUri);
    event NftSalePriceSet(uint256 price);
    event TreasurySet(address treasuryAddress);
    event NativeBuy(address to, uint256 tokenId, uint256 price);
    event DefaultRoyaltySet(address indexed receiver, uint96 feeNumerator);
    event DefaultRoyaltyDeleted();

    error NftPriceExceedsMsgValue(uint256 nftPrice, uint256 msgValue);
    error UriQueryNotExist(uint256 tokenId);
    error CallerIsNotAnTokenOwnerOrApproved(address caller, uint256 tokenId);
    error TreasuryPaymentFailed();
    error ZeroAddress();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseImageURI,
        string memory _chainName,
        address _espHypErc20,
        address payable _treasury,
        uint256 _nftSalePrice
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, _espHypErc20);

        baseImageURI = _baseImageURI;
        chainName = _chainName;
        _setTreasuryAndPrice(_treasury, _nftSalePrice);
        _setDefaultRoyalty(_treasury, DEFAULT_ROYALTY_BPS);
    }

    /**
     * @notice Mint token on 'to' address
     * If caller is not EspHypERC20 (not xchain mint) we charge caller
     * to pay for NFT in native currency in the same chain
     * @dev Only accounts with MINTER_ROLE can call without native currency payment.
     */
    function mint(address to) external payable {
        bool xChainMint = hasRole(MINTER_ROLE, msg.sender);
        uint256 tokenId = lastTokenId++;

        if (!xChainMint) _nativeBuy(to, tokenId);
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

    function setTreasuryAndPrice(address payable _treasury, uint256 _nftSalePrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setTreasuryAndPrice(_treasury, _nftSalePrice);
    }

    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal {
        if (receiver == address(0)) revert ZeroAddress();
        royaltyReceiver = receiver;
        royaltyFeeNumerator = feeNumerator;
        emit DefaultRoyaltySet(receiver, feeNumerator);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (receiver == address(0)) revert ZeroAddress();
        _setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyaltySet(receiver, feeNumerator);
    }

    function _setTreasuryAndPrice(address payable _treasury, uint256 _nftSalePrice) internal {
        if (_treasury == address(0)) revert ZeroAddress();
        treasury = _treasury;
        emit TreasurySet(_treasury);

        nftSalePrice = _nftSalePrice;
        emit NftSalePriceSet(_nftSalePrice);
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

    function _nativeBuy(address to, uint256 tokenId) internal {
        if (msg.value != nftSalePrice) revert NftPriceExceedsMsgValue(nftSalePrice, msg.value);

        (bool success,) = treasury.call{value: nftSalePrice}("");
        if (!success) revert TreasuryPaymentFailed();
        emit NativeBuy(to, tokenId, nftSalePrice);
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

    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (treasury, salePrice * 500 / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, IERC165) returns (bool) {
        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        if (interfaceId == type(IERC721).interfaceId) {
            return true;
        }
        if (interfaceId == type(IAccessControl).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}
