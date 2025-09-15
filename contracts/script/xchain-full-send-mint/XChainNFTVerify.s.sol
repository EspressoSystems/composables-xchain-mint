// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../../script/configs/HyperlaneAddressesConfig.sol";
import {HypERC20} from "@hyperlane-core/solidity/contracts/token/HypERC20.sol";
import "../../src/mocks/MockERC721.sol";

contract XChainNFTVerifyScript is Script, Test, HyperlaneAddressesConfig {
    function run() public view {
        uint256 amount = vm.envUint("XCHAIN_AMOUNT_WEI");
        uint256 treasuryHypBalanceBefore = vm.envUint("BALANCE_SYNTHETIC_BEFORE");
        uint256 deployerBalanceBefore = vm.envUint("DEPLOYER_BALANCE_BEFORE");
        uint256 nftsCountBefore = vm.envUint("NFTS_COUNT_BEFORE");

        address treasury = vm.envAddress("TREASURY_ADDRESS");
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        address marketplaceAddress = vm.envAddress("MARKETPLACE_ADDRESS");

        address payable hypERC20TokenAddress = payable(vm.envAddress("HYPERLANE_TOKEN_ADDRESS"));

        HypERC20 hypERC20Token = HypERC20(hypERC20TokenAddress);

        // Treasury receives bridged tokens
        uint256 treasuryHypBalanceAfter = hypERC20Token.balanceOf(treasury);
        assertEq(treasuryHypBalanceAfter, amount + treasuryHypBalanceBefore);

        // Deployer native tokens balance should be the same before and after crosschain send.
        assertEq(deployer.balance, deployerBalanceBefore);

        MockERC721 marketplace = MockERC721(marketplaceAddress);
        uint256 nftsCount = marketplace.nextTokenId();
        assertEq(nftsCount, nftsCountBefore + 1);
    }
}
