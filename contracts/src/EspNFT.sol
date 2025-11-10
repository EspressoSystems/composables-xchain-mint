// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../src/libs/SaleTimeAndPrice.sol";
import "../src/libs/Treasury.sol";

/**
 * @title EspNFT — ERC721 with role-restricted minting, base-IPFS tokenImage token generation and onchain metadata.
 * @notice Minting restricted to MINTER_ROLE.
 * @dev Uses OpenZeppelin ERC721 + AccessControl
 */
contract EspNFT is ERC721, SaleTimeAndPrice, Treasury, AccessControl, IERC2981 {
    using Strings for uint256;
    using Strings for string;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public royaltyReceiver;
    uint96 public royaltyFeeNumerator;
    uint96 public constant DEFAULT_ROYALTY_BPS = 500; // 5%

    uint256 public lastTokenId;
    string private baseImageURI;
    string private chainName;

    mapping(uint256 tokenId => uint256 machineType) public machineTypes;

    event TokenMinted(address indexed to, uint256 indexed tokenId, uint256 machineType);
    event BaseImageUriChanged(string oldBaseImageUri, string newBaseImageUri);
    event TreasurySet(address treasuryAddress);
    event NativeBuy(address to, uint256 tokenId, uint256 price);
    event DefaultRoyaltySet(address indexed receiver, uint96 feeNumerator);
    event DefaultRoyaltyDeleted();

    error NftPriceExceedsMsgValue(uint256 nftPrice, uint256 msgValue);
    error UriQueryNotExist(uint256 tokenId);
    error CallerIsNotAnTokenOwnerOrApproved(address caller, uint256 tokenId);
    error TreasuryPaymentFailed(address treasury);
    error RoyaltyFeeTooHigh();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseImageURI,
        string memory _chainName,
        address _espHypErc20,
        TreasuryConfig memory _treasury,
        uint256 _nftSalePrice,
        uint256 _startSale
    ) ERC721(_name, _symbol) SaleTimeAndPrice(_startSale, _nftSalePrice) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, _espHypErc20);
        baseImageURI = _baseImageURI;
        chainName = _chainName;

        _setTreasury(_treasury);
        _setDefaultRoyalty(_treasury.espresso, DEFAULT_ROYALTY_BPS);
    }

    /**
     * @notice Mint token on 'to' address
     * If caller is not EspHypERC20 (not xchain mint) we charge caller
     * to pay for NFT in native currency in the same chain.
     * Sale is only open during 3 weeks after sale starts.
     * @dev Only accounts with MINTER_ROLE can call without native currency payment.
     */
    function mint(address to) external payable {
        bool xChainMint = hasRole(MINTER_ROLE, msg.sender);
        uint256 tokenId = ++lastTokenId;
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

    function setSalePrice(uint256 _nftSalePrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPrice(_nftSalePrice);
    }

    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal {
        if (receiver == address(0)) revert ZeroAddress();
        if (feeNumerator > ONE_HUNDRED_PERCENT) revert RoyaltyFeeTooHigh();
        royaltyReceiver = receiver;
        royaltyFeeNumerator = feeNumerator;
        emit DefaultRoyaltySet(receiver, feeNumerator);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (receiver == address(0)) revert ZeroAddress();
        _setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyaltySet(receiver, feeNumerator);
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
                '","description": "Mint across chains without bridging. Powered by Espresso, ApeChain, and RARI Chain to showcase seamless, composable NFT minting.","image": "',
                imageURL,
                '","attributes": [{ "trait_type": "Theme", "value": "',
                machineTheme,
                '" }]}'
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

    function _nativeBuy(address to, uint256 tokenId) internal whenSaleOpen {
        if (msg.value != nftSalePriceWei) revert NftPriceExceedsMsgValue(nftSalePriceWei, msg.value);

        uint256 mainAmount = nftSalePriceWei * treasury.percentageEspresso / ONE_HUNDRED_PERCENT;
        (bool success,) = treasury.espresso.call{value: mainAmount}("");
        if (!success) revert TreasuryPaymentFailed(treasury.espresso);

        if (treasury.percentageEspresso != ONE_HUNDRED_PERCENT) {
            (success,) = treasury.partner.call{value: nftSalePriceWei - mainAmount}("");
            if (!success) revert TreasuryPaymentFailed(treasury.partner);
        }

        emit NativeBuy(to, tokenId, nftSalePriceWei);
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

    // @dev the first parameter is the tokenId, but we don't use it here
    // @dev the second parameter is the salePrice
    // @dev returns the royalty receiver and the royalty amount
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyReceiver, (salePrice * royaltyFeeNumerator) / ONE_HUNDRED_PERCENT);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl, IERC165)
        returns (bool)
    {
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
