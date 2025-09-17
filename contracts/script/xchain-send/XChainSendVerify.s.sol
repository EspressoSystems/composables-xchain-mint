// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../../script/configs/HyperlaneAddressesConfig.sol";
import {HypERC20} from "@hyperlane-core/solidity/contracts/token/HypERC20.sol";

contract XChainSendVerifyScript is Script, Test, HyperlaneAddressesConfig {
    function run() public view {
        uint256 amount = vm.envUint("XCHAIN_AMOUNT_WEI");
        uint256 recipientHypBalanceBefore = vm.envUint("BALANCE_SYNTHETIC_BEFORE");
        uint256 deployerBalanceBefore = vm.envUint("DEPLOYER_BALANCE_BEFORE");

        address recipient = vm.envAddress("TOKENS_RECIPIENT");
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");

        address payable hypERC20TokenAddress = payable(vm.envAddress("SOURCE_HYPERLANE_TOKEN_ADDRESS"));

        HypERC20 hypERC20Token = HypERC20(hypERC20TokenAddress);

        uint256 recipientHypBalanceAfter = hypERC20Token.balanceOf(recipient);
        assertEq(recipientHypBalanceAfter, amount + recipientHypBalanceBefore);

        // Deployer native tokens balance should be the same before and after crosschain send.
        assertEq(deployer.balance, deployerBalanceBefore);
    }
}
