pragma solidity 0.8.30;

import {Test} from "forge-std/src/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";
import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EspNFT} from "../src/EspNFT.sol";
import {SaleTimeAndPrice} from "../src/libs/SaleTimeAndPrice.sol";

contract EspNftTest is Test, HyperlaneAddressesConfig {
    using TypeCasts for address;
    using Strings for uint256;
    using Strings for string;

    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = espSourceConfig.destinationChainId;
    string public name = "Bridgeless Minting NFT";
    string public symbol = "BM";
    string public baseImageUri = "https://xchain-nft.s3.us-east-2.amazonaws.com/rari/";
    uint256 nftPrice = 10 ether;
    EspNFT public espNft;

    address public deployer = espSourceConfig.deployer;
    address public recipient = makeAddr("recipient");
    address public approvedOperator = makeAddr("approvedOperator");
    address public notApprovedOperator = makeAddr("notApprovedOperator");
    address public notAdmin = makeAddr("notAdmin");
    address public espNftAddress = vm.envAddress("DESTINATION_NFT_ADDRESS");
    address public deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");
    address public treasury = vm.envAddress("ESPRESSO_TREASURY_ADDRESS");
    uint256 public espressoTreasuryPercentage = 7500;
    uint256 public espressoRoyaltiesPercentage = 500;
    uint256 public startSale = vm.envUint("SALE_TIME_START");
    uint256 public endSale = vm.envUint("SALE_TIME_END");
    address public espHypERC20Address = espSourceConfig.sourceToDestinationEspTokenProxy;
    uint256 public hookPayment = vm.envUint("BRIDGE_BACK_PAYMENT_AMOUNT_WEI");
    uint32 public destinationDomainId = uint32(vm.envUint("SOURCE_CHAIN_ID"));

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
        espNft = EspNFT(espNftAddress);
        vm.warp(startSale);
    }

    /**
     * @dev Test checks destination ERC20 token name and symbol.
     */
    function testVerifyNftNameAndSymbol() public {
        vm.selectFork(destinationChain);

        assertEq(espNft.symbol(), symbol);
        assertEq(espNft.name(), name);
        assertEq(espNft.nftSalePriceWei(), nftPrice);
        assertEq(espNft.lastTokenId(), 0);
    }

    /**
     * @dev Test checks native buy works in the same chain.
     */
    function testVerifyNativeBuyMintsToken() public {
        vm.selectFork(destinationChain);
        uint256 tokenId = 1;

        assertEq(espNft.lastTokenId(), 0);

        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), recipient, tokenId);
        vm.expectEmit(true, true, true, false);
        emit EspNFT.TokenMinted(recipient, tokenId, 1);

        espNft.mint{value: nftPrice}(recipient);

        assertEq(espNft.lastTokenId(), tokenId);
    }

    /**
     * @dev Test verifying tokens metadata for minted tokens.
     */
    function testVerifyTokensMetadata() public {
        vm.selectFork(destinationChain);
        mintNftAndVerifyMetadata(20);
    }

    function mintNftAndVerifyMetadata(uint256 nftAmount) public {
        uint256 tokenId;

        for (uint256 i = 1; i <= nftAmount; i++) {
            tokenId = i;
            assertEq(espNft.lastTokenId(), tokenId - 1);
            espNft.mint{value: nftPrice}(recipient);
            assertEq(espNft.lastTokenId(), tokenId);
            assertEq(espNft.tokenURI(tokenId), getNftMetadata(baseImageUri, tokenId));
        }
    }

    function getNftMetadata(string memory imageUri, uint256 tokenId) public view returns (string memory) {
        uint256 machineType = espNft.machineTypes(tokenId);
        string memory machineTheme = getMachineTheme(machineType);
        string memory imageURL = string(abi.encodePacked(imageUri, machineTheme, ".png"));

        string memory json = string(
            abi.encodePacked(
                '{"name": "Rari Espresso Machine #',
                tokenId.toString(),
                '","description": "Mint across chains without bridging. Powered by Espresso, ApeChain, and RARI Chain to showcase seamless, composable NFT minting.","image": "',
                imageURL,
                '","attributes": [{ "trait_type": "Theme", "value": "',
                machineTheme,
                '" }]}'
            )
        );
        return string(abi.encodePacked("data:application/json;utf8,", json));
    }

    function getMachineTheme(uint256 machineType) internal pure returns (string memory) {
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

    /**
     * @dev Test verifying default and treasury constructor params.
     */
    function testVerifyDefaultAndTreasuryConstructorParams() public {
        vm.selectFork(destinationChain);

        (address espresso, address partner, uint256 percentageEspresso) = espNft.getTreasury();
        assertEq(espresso, treasury);
        assertEq(partner, treasury);
        assertEq(espressoTreasuryPercentage, percentageEspresso);

        assertEq(espNft.royaltyReceiver(), treasury);
        assertEq(espNft.royaltyFeeNumerator(), espressoRoyaltiesPercentage);
        assertEq(espNft.DEFAULT_ROYALTY_BPS(), espressoRoyaltiesPercentage);
        assertEq(espNft.espHypErc20(), espHypERC20Address);

        assertEq(espNft.startSale(), startSale);
        assertEq(espNft.endSale(), endSale);
    }

    /**
     * @dev Test checks that not Admin is not able to update image base Uri
     */
    function testRevertSetNewImageBaseUriNotAdmin() public {
        vm.selectFork(destinationChain);
        string memory newImageUri = "ImageUri/";

        vm.expectRevert(bytes(getAccessControlError(notAdmin, espNft.DEFAULT_ADMIN_ROLE())));
        vm.prank(notAdmin);
        espNft.setBaseImageUri(newImageUri);
    }

    function getAccessControlError(address caller, bytes32 role) public pure returns (string memory) {
        return string.concat(
            "AccessControl: account ",
            Strings.toHexString(uint160(caller), 20),
            " is missing role ",
            Strings.toHexString(uint256(role), 32)
        );
    }

    /**
     * @dev Test checks that admin is able to update image base Uri.
     */
    function testSetNewImageBaseUri() public {
        vm.selectFork(destinationChain);

        string memory newImageUri = "ImageUri/";
        uint256 tokenId = 1;

        espNft.mint{value: nftPrice}(recipient);
        assertEq(espNft.tokenURI(tokenId), getNftMetadata(baseImageUri, tokenId));

        vm.prank(deployerAddress);
        vm.expectEmit(true, true, true, true);
        emit EspNFT.BaseImageUriChanged(baseImageUri, newImageUri);
        espNft.setBaseImageUri(newImageUri);

        assertEq(espNft.tokenURI(tokenId), getNftMetadata(newImageUri, tokenId));
    }

    /**
     * @dev Test checks that Admin is able to change NFT price.
     */
    function testSetNewSalePrice() public {
        vm.selectFork(destinationChain);

        uint256 newNftPrice = 0.1 ether;

        assertEq(espNft.nftSalePriceWei(), nftPrice);

        vm.prank(deployerAddress);
        vm.expectEmit(true, true, true, true);
        emit SaleTimeAndPrice.NftSalePriceSet(newNftPrice);
        espNft.setSalePrice(newNftPrice);

        assertEq(espNft.nftSalePriceWei(), newNftPrice);
    }

    /**
     * @dev Test checks that not Admin is not able to update sale price.
     */
    function testRevertSalePriceNotAdmin() public {
        vm.selectFork(destinationChain);
        uint256 newNftPrice = 0.1 ether;

        vm.expectRevert(bytes(getAccessControlError(notAdmin, espNft.PRICE_ADMIN_ROLE())));
        vm.prank(notAdmin);
        espNft.setSalePrice(newNftPrice);

        assertEq(espNft.nftSalePriceWei(), nftPrice);
    }

    /**
     * @dev Test checks that admin is not able to set low NFT price.
     */
    function testRevertSalePriceLowerThanAllowed() public {
        vm.selectFork(destinationChain);
        uint256 lowPrice = 999;
        uint256 minPrice = 1000;

        vm.expectRevert(abi.encodeWithSelector(SaleTimeAndPrice.LowPriceInWei.selector, minPrice, lowPrice));
        vm.prank(deployerAddress);
        espNft.setSalePrice(lowPrice);
        assertEq(espNft.nftSalePriceWei(), nftPrice);
    }

    /**
     * @dev Test checks when sale is open or not depending on the time.
     */
    function testIsSaleOpen() public {
        vm.selectFork(destinationChain);

        vm.warp(startSale - 1);
        assertFalse(espNft.isSaleOpen());

        vm.warp(endSale + 1);
        assertFalse(espNft.isSaleOpen());

        vm.warp(startSale);
        assertTrue(espNft.isSaleOpen());
    }

    /**
     * @dev Test checks that tokenURI reverts when providing not existing tokenId.
     */
    function testRevertGetTokenURINotValidTokenId() public {
        vm.selectFork(destinationChain);
        uint256 tokenId = 5;

        vm.expectRevert(abi.encodeWithSelector(EspNFT.UriQueryNotExist.selector, tokenId));
        espNft.tokenURI(tokenId);
    }

    /**
     * @dev Test checks that it generates short token Uri when Image Uri is not set.
     */
    function testVerifyTokensMetadataWhenImageBaseUriNotSet() public {
        vm.selectFork(destinationChain);

        string memory newImageUri = "";
        uint256 tokenId = 1;

        espNft.mint{value: nftPrice}(recipient);
        assertEq(espNft.tokenURI(tokenId), getNftMetadata(baseImageUri, tokenId));

        vm.prank(deployerAddress);
        espNft.setBaseImageUri(newImageUri);

        assertEq(espNft.tokenURI(tokenId), tokenId.toString());
    }

    /**
     * @dev Test checks owner is able to burn NFT.
     */
    function testBurnFromOwner() public {
        vm.selectFork(destinationChain);
        uint256 tokenId = 1;

        espNft.mint{value: nftPrice}(recipient);
        assertEq(espNft.tokenURI(tokenId), getNftMetadata(baseImageUri, tokenId));

        vm.prank(recipient);
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(recipient, address(0), tokenId);
        espNft.burn(tokenId);

        vm.expectRevert(abi.encodeWithSelector(EspNFT.UriQueryNotExist.selector, tokenId));
        espNft.tokenURI(tokenId);
    }

    /**
     * @dev Test checks that approved operator is able to burn owners NFT.
     */
    function testBurnFromApprovedOperator() public {
        vm.selectFork(destinationChain);
        uint256 tokenId = 1;

        espNft.mint{value: nftPrice}(recipient);
        assertEq(espNft.tokenURI(tokenId), getNftMetadata(baseImageUri, tokenId));

        vm.prank(recipient);
        espNft.approve(approvedOperator, tokenId);

        vm.prank(approvedOperator);
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(recipient, address(0), tokenId);
        espNft.burn(tokenId);

        vm.expectRevert(abi.encodeWithSelector(EspNFT.UriQueryNotExist.selector, tokenId));
        espNft.tokenURI(tokenId);
    }

    /**
     * @dev Test checks that not approved operator is not able to burn owners NFT.
     */
    function testRevertBurnFromNotApprovedOperator() public {
        vm.selectFork(destinationChain);
        uint256 tokenId = 1;

        espNft.mint{value: nftPrice}(recipient);
        assertEq(espNft.tokenURI(tokenId), getNftMetadata(baseImageUri, tokenId));

        vm.prank(notApprovedOperator);
        vm.expectRevert(
            abi.encodeWithSelector(EspNFT.CallerIsNotAnTokenOwnerOrApproved.selector, notApprovedOperator, tokenId)
        );
        espNft.burn(tokenId);

        assertEq(espNft.tokenURI(tokenId), getNftMetadata(baseImageUri, tokenId));
    }

    /**
     * @dev Test checks native buy reverts if payment is low.
     */
    function testReverNativeBuyMintValueLessThanSalePrice() public {
        uint256 lowPrice = nftPrice - 1;
        vm.selectFork(destinationChain);

        vm.expectRevert(abi.encodeWithSelector(EspNFT.NftPriceExceedsMsgValue.selector, nftPrice, lowPrice));
        espNft.mint{value: lowPrice}(recipient);
    }

    /**
     * @dev Test checks native buy reverts if payment is more than nftPrice.
     */
    function testReverNativeBuyMintValueMoreThanSalePrice() public {
        uint256 highPrice = nftPrice + 1;
        vm.selectFork(destinationChain);

        vm.expectRevert(abi.encodeWithSelector(EspNFT.NftPriceExceedsMsgValue.selector, nftPrice, highPrice));
        espNft.mint{value: highPrice}(recipient);
    }

    /**
     * @dev Test checks native buy reverts if sale not started.
     */
    function testReverNativeBuyMintIfSaleNotStarted() public {
        vm.selectFork(destinationChain);

        uint256 beforeSaleStart = startSale - 1;

        vm.warp(beforeSaleStart);

        vm.expectRevert(
            abi.encodeWithSelector(
                SaleTimeAndPrice.SaleFinishedOrNotStarted.selector, startSale, endSale, beforeSaleStart
            )
        );
        espNft.mint{value: nftPrice}(recipient);
    }

    /**
     * @dev Test checks native buy reverts if sale finished.
     */
    function testReverNativeBuyMintWhenSaleFinished() public {
        vm.selectFork(destinationChain);

        uint256 afterSaleEnd = endSale + 1;

        vm.warp(afterSaleEnd);

        vm.expectRevert(
            abi.encodeWithSelector(SaleTimeAndPrice.SaleFinishedOrNotStarted.selector, startSale, endSale, afterSaleEnd)
        );
        espNft.mint{value: nftPrice}(recipient);
    }

    /**
     * @dev Test checks mint from caller with minter role with no native payment.
     */
    function testVerifyMintTokenFromMinterRoleWithNoPayment() public {
        vm.selectFork(destinationChain);
        uint256 tokenId = 1;

        assertEq(espNft.lastTokenId(), 0);

        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), recipient, tokenId);
        vm.expectEmit(true, true, true, false);
        emit EspNFT.TokenMinted(recipient, tokenId, 1);

        vm.prank(espHypERC20Address);
        espNft.mint(recipient);

        assertEq(espNft.lastTokenId(), tokenId);
    }
}
