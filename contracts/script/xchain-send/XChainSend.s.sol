// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../../script/configs/HyperlaneAddressesConfig.sol";
import {HypNative} from "@hyperlane-core/solidity/contracts/token/HypNative.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";

contract XChainSendScript is Script, Test, HyperlaneAddressesConfig {
    using TypeCasts for address;

    function run() public {
        uint256 payGasFees = 0.001 ether;

        uint256 amount = vm.envUint("XCHAIN_AMOUNT_WEI");
        address recipient = vm.envAddress("TOKENS_RECIPIENT");
        address payable hypNativeToken = payable(vm.envAddress("SOURCE_HYPERLANE_TOKEN_ADDRESS"));

        uint32 sourceDestinationChainId = uint32(vm.envUint("DESTINATION_CHAIN_ID"));

        vm.startBroadcast();
        HypNative hyperlaneNativeToken = HypNative(hypNativeToken);

        hyperlaneNativeToken.transferRemote{value: payGasFees + amount}(sourceDestinationChainId, recipient.addressToBytes32(), amount);
        vm.stopBroadcast();
    }
}
