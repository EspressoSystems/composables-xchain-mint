// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {HypNative} from "@hyperlane-core/solidity/contracts/token/HypNative.sol";

contract XChainSendScript is Script, Test, HyperlaneAddressesConfig {
    function run() public {
        uint256 payGasFees = 0.001 ether;

        uint256 amount = vm.envUint("XCHAIN_AMOUNT_WEI");
        address recipient = vm.envAddress("TOKENS_RECIPIENT");
        address payable hypNativeToken = payable(vm.envAddress("HYPERLANE_TOKEN_ADDRESS"));

        uint32 sourceDestinationChainId = uint32(vm.envUint("DESTINATION_CHAIN_ID"));

        vm.startBroadcast();
        HypNative hyperlaneNativeToken = HypNative(hypNativeToken);

        hyperlaneNativeToken.transferRemote{value: payGasFees + amount}(sourceDestinationChainId, _addressToBytes32(recipient), amount);
        vm.stopBroadcast();
    }

    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
