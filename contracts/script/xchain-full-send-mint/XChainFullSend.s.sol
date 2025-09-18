// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";

import {HyperlaneAddressesConfig} from "../../script/configs/HyperlaneAddressesConfig.sol";
import {HypNative} from "@hyperlane-core/solidity/contracts/token/HypNative.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";


contract XChainFullSendScript is Script, HyperlaneAddressesConfig {
    using TypeCasts for address;

    function run() public {
        uint256 payGasFees = 0.001 ether;

        uint256 amount = vm.envUint("XCHAIN_AMOUNT_WEI");
        address recipient = vm.envAddress("TOKENS_RECIPIENT");
        address payable hypNativeToken = payable(vm.envAddress("HYPERLANE_TOKEN_ADDRESS"));

        uint32 destinationChainId = uint32(vm.envUint("CHAIN_ID"));

        vm.startBroadcast();
        HypNative hyperlaneNativeToken = HypNative(hypNativeToken);

        hyperlaneNativeToken.transferRemote{value: payGasFees + amount}(
            destinationChainId, recipient.addressToBytes32(), amount
        );
        vm.stopBroadcast();
    }
}
