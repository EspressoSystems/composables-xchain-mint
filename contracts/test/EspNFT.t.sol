pragma solidity 0.8.30;

import {Test} from "forge-std/src/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";
import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import "../src/EspNFT.sol";

contract EspNftTest is Test, HyperlaneAddressesConfig {
    using TypeCasts for address;
    using Strings for uint256;
    using Strings for string;

    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = espSourceConfig.destinationChainId;
    string public name = "Espresso Composables NFT";
    string public symbol = "EC";
    string public baseImageUri = "https://xchain-nft.s3.us-east-2.amazonaws.com/rari/";
    uint256 nftPrice = 10 ether;
    EspNFT public espNft;

    address public deployer = espSourceConfig.deployer;
    address public recipient = address(1);
    address public espNftAddress = vm.envAddress("DESTINATION_NFT_ADDRESS");
    address public treasury = vm.envAddress("ESPRESSO_TREASURY_ADDRESS");
    address public nftAddress = vm.envAddress("DESTINATION_NFT_ADDRESS");
    uint256 public hookPayment = vm.envUint("BRIDGE_BACK_PAYMENT_AMOUNT_WEI");
    uint32 public destinationDomainId = uint32(vm.envUint("SOURCE_CHAIN_ID"));

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
        espNft = EspNFT(espNftAddress);
    }

    /**
     * @dev Test checks destination ERC20 token name and symbol
     */
    function testVerifyNftNameAndSymbol() public {
        vm.selectFork(destinationChain);

        assertEq(espNft.symbol(), symbol);
        assertEq(espNft.name(), name);
        assertEq(espNft.nftSalePriceWei(), nftPrice);
        assertEq(espNft.lastTokenId(), 0);
    }

    /**
     * @dev Test checks native buy works in the same chain
     */
    function testVerifyNativeBuyMintsToken() public {
        vm.selectFork(destinationChain);
        uint256 tokenId = 1;

        assertEq(espNft.lastTokenId(), 0);

        espNft.mint{value: nftPrice}(recipient);

        assertEq(espNft.lastTokenId(), tokenId);
    }

    /**
     * @dev Test verifying tokens metadata for minted tokens
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
            assertEq(espNft.tokenURI(tokenId), getNftMetadata(tokenId));
        }
    }

    function getNftMetadata(uint256 tokenId) public view returns (string memory) {
        uint256 machineType = espNft.machineTypes(tokenId);
        string memory machineTheme = getMachineTheme(machineType);
        string memory imageURL = string(abi.encodePacked(baseImageUri, machineTheme, ".png"));

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
}
