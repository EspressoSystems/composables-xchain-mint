// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title EspNFT — ERC721 with role-restricted minting, base-IPFS tokenImage token generation and onchain metadata.
 * @notice Minting restricted to MINTER_ROLE.
 * @dev Uses OpenZeppelin ERC721 + AccessControl
 */
contract EspNFT is ERC721, AccessControl, IERC2981 {
    using Strings for uint256;
    using Strings for string;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // The NFT sale price in Wei
    uint256 public nftSalePrice;
    address payable public treasury1;
    address payable public treasury2;
    uint96 public treasurySplitBps;
    address public royaltyReceiver;
    uint96 public royaltyFeeNumerator;
    uint96 public constant DEFAULT_ROYALTY_BPS = 500; // 5%
    uint96 public constant MAX_TREASURY_BPS = 10000;

    uint256 public lastTokenId;
    string private baseImageURI;
    string private chainName;

    mapping(uint256 tokenId => uint256 machineType) public machineTypes;

    event TokenMinted(address indexed to, uint256 indexed tokenId, uint256 machineType);
    event BaseImageUriChanged(string oldBaseImageUri, string newBaseImageUri);
    event NftSalePriceSet(uint256 price);
    event TreasuriesSet(address treasury1, address treasury2, uint96 splitBps);
    event NativeBuy(address to, uint256 tokenId, uint256 price);
    event DefaultRoyaltySet(address indexed receiver, uint96 feeNumerator);
    event DefaultRoyaltyDeleted();

    error NftPriceExceedsMsgValue(uint256 nftPrice, uint256 msgValue);
    error UriQueryNotExist(uint256 tokenId);
    error CallerIsNotAnTokenOwnerOrApproved(address caller, uint256 tokenId);
    error TreasuryPaymentFailed();
    error ZeroAddress();
    error RoyaltyFeeTooHigh();
    error TreasurySplitTooHigh();

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

    function setTreasuries(address payable _treasury1, address payable _treasury2, uint96 _treasurySplitBps)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setTreasuries(_treasury1, _treasury2, _treasurySplitBps);
    }

    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal {
        if (receiver == address(0)) revert ZeroAddress();
        if (feeNumerator > 10000) revert RoyaltyFeeTooHigh();
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
        _setTreasuries(_treasury, _treasury, MAX_TREASURY_BPS);
        nftSalePrice = _nftSalePrice;
        emit NftSalePriceSet(_nftSalePrice);
    }

    function _setTreasuries(address payable _treasury1, address payable _treasury2, uint96 _treasurySplitBps) internal {
        if (_treasury1 == address(0) || _treasury2 == address(0)) revert ZeroAddress();
        if (_treasurySplitBps > MAX_TREASURY_BPS) revert TreasurySplitTooHigh();
        treasury1 = _treasury1;
        treasury2 = _treasury2;
        treasurySplitBps = _treasurySplitBps;
        emit TreasuriesSet(_treasury1, _treasury2, _treasurySplitBps);
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
        if (treasury1 == treasury2) {
            (bool successSame,) = treasury1.call{value: nftSalePrice}("");
            if (!successSame) revert TreasuryPaymentFailed();
        } else {
            uint256 amountTreasury1 = (nftSalePrice * treasurySplitBps) / MAX_TREASURY_BPS;
            uint256 amountTreasury2 = nftSalePrice - amountTreasury1;

            if (amountTreasury1 > 0) {
                (bool success1,) = treasury1.call{value: amountTreasury1}("");
                if (!success1) revert TreasuryPaymentFailed();
            }

            if (amountTreasury2 > 0) {
                (bool success2,) = treasury2.call{value: amountTreasury2}("");
                if (!success2) revert TreasuryPaymentFailed();
            }
        }
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

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyReceiver, (salePrice * royaltyFeeNumerator) / 10000);
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
