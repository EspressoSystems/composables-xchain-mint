// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Test} from "forge-std/src/Test.sol";
import {EspNFT} from "../src/EspNFT.sol";
import "../src/libs/Treasury.sol";
import "../src/libs/SaleTimeAndPrice.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";


// This file contains unit tests for the EspNFT contract, focusing on royalty management, access control, and constructor initialization.


contract RoyaltyEspNFTTest is Test {
    uint256 public constant ONE_HUNDRED_PERCENT = 10000; // 100%
    EspNFT public nft;
    address payable public treasury = payable(makeAddr("treasury"));
    address payable public partner = payable(makeAddr("partner"));
    address public recipient = makeAddr("recipient");
    uint256 public nftPrice = 0.1 ether;
    uint256 public mainTreasuryPercentage = 7500;
    uint256 public currentTime = block.timestamp;
    string public baseUri = "https://example.com/";
    string public chain = "test";
    address public hypErc20 = makeAddr("hyp");

    function setUp() public {
        Treasury.TreasuryConfig memory treasuryConfig =
            Treasury.TreasuryConfig(treasury, partner, mainTreasuryPercentage);
        nft = new EspNFT("Name", "SYM", baseUri, chain, hypErc20, treasuryConfig, nftPrice, currentTime);
    }

    function testConstructorSetsDefaultRoyalty() public view {
        (address receiver, uint256 amount) = nft.royaltyInfo(0, 10000);
        assertEq(receiver, treasury);
        assertEq(amount, 500);
    }

    function testNonAdminCannotSetDefaultRoyalty() public {
        address nonAdmin = makeAddr("nonAdmin");
        string memory expectedError = string.concat(
            "AccessControl: account ",
            Strings.toHexString(uint160(nonAdmin), 20),
            " is missing role ",
            Strings.toHexString(uint256(nft.DEFAULT_ADMIN_ROLE()), 32)
        );
        vm.expectRevert(bytes(expectedError));
        vm.prank(nonAdmin);
        nft.setDefaultRoyalty(makeAddr("newReceiver"), 100);
    }

    function testRoyaltyInfoReturnsCorrectValues() public view {
        (address receiver, uint256 amount) = nft.royaltyInfo(0, 100 ether);
        assertEq(receiver, treasury);
        assertEq(amount, 5 ether);
    }

    function testRoyaltyInfoWithDifferentSalePrice() public view {
        (address receiver, uint256 amount) = nft.royaltyInfo(0, 200 ether);
        assertEq(receiver, treasury);
        assertEq(amount, 10 ether);
    }

    function testSetDefaultRoyaltyUpdatesValues() public {
        address newReceiver = makeAddr("newReceiver");
        uint96 newFee = 1000; // 10%
        nft.setDefaultRoyalty(newReceiver, newFee);
        (address receiver, uint256 amount) = nft.royaltyInfo(0, 100 ether);
        assertEq(receiver, newReceiver);
        assertEq(amount, 10 ether);
    }

    function testSetDefaultRoyaltyWithFeeTooHighReverts() public {
        vm.expectRevert(EspNFT.RoyaltyFeeTooHigh.selector);
        nft.setDefaultRoyalty(makeAddr("receiver"), 10001);
    }

    function testSetDefaultRoyaltyWithZeroAddressReverts() public {
        vm.expectRevert(Treasury.ZeroAddress.selector);
        nft.setDefaultRoyalty(address(0), 100);
    }

    function testVerifyNativeBuyMintsTokenWithPartnerTreasury() public {
        uint256 tokenId = 1;
        assertEq(nft.lastTokenId(), 0);
        assertEq(treasury.balance, 0);
        assertEq(partner.balance, 0);

        nft.mint{value: nftPrice}(recipient);

        assertEq(nft.lastTokenId(), tokenId);
        assertEq(treasury.balance, nftPrice * mainTreasuryPercentage / ONE_HUNDRED_PERCENT);
        assertEq(partner.balance, nftPrice * (ONE_HUNDRED_PERCENT - mainTreasuryPercentage) / ONE_HUNDRED_PERCENT);
    }

    function testVRevertSetNotValidSaleTimeStart() public {
        uint256 saleStart = block.timestamp - 1;
        Treasury.TreasuryConfig memory treasuryConfig =
            Treasury.TreasuryConfig(treasury, treasury, mainTreasuryPercentage);

        vm.expectRevert(abi.encodeWithSelector(SaleTimeAndPrice.StartDateInPastNotAllowed.selector, saleStart, block.timestamp));
        new EspNFT("Name", "SYM", baseUri, chain, hypErc20, treasuryConfig, nftPrice, saleStart);
    }

}
