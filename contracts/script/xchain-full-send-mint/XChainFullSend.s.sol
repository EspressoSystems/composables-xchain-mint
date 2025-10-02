// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";

import {HyperlaneAddressesConfig} from "../../script/configs/HyperlaneAddressesConfig.sol";
import {EspHypNative} from "../../src/EspHypNative.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";

contract XChainFullSendScript is Script, HyperlaneAddressesConfig {
    using TypeCasts for address;

    function run() public {
        uint256 payGasFees = 0.001 ether;

        uint256 amount = vm.envUint("XCHAIN_AMOUNT_WEI");
        address recipient = vm.envAddress("TOKENS_RECIPIENT");
        address payable hypNativeToken = payable(vm.envAddress("HYPERLANE_TOKEN_ADDRESS"));

        vm.startBroadcast();
        EspHypNative hyperlaneNativeToken = EspHypNative(hypNativeToken);

        hyperlaneNativeToken.initiateCrossChainNftPurchase{value: payGasFees + amount}(recipient.addressToBytes32());
        vm.stopBroadcast();
    }
}
