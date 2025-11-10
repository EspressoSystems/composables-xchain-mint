// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Test} from "forge-std/src/Test.sol";
import {EspNFT} from "../src/EspNFT.sol";
import "../src/libs/Treasury.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/* <ai_context>
This file contains unit tests for the EspNFT contract, focusing on royalty management, access control, and constructor initialization.
</ai_context> */

contract RoyaltyEspNFTTest is Test {
    EspNFT public nft;
    address payable public treasury = payable(makeAddr("treasury"));
    uint256 public nftPrice = 0.1 ether;
    uint256 public mainTreasuryPercentage = 100;
    uint256 public currentTime = block.timestamp;
    string public baseUri = "https://example.com/";
    string public chain = "test";
    address public hypErc20 = makeAddr("hyp");

    function setUp() public {
        Treasury.TreasuryConfig memory treasuryConfig =
            Treasury.TreasuryConfig(treasury, treasury, mainTreasuryPercentage);
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
}
