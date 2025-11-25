// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";

import {EspHypNative} from "../../src/EspHypNative.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";

contract InitiateCrossChainNftPurchaseScript is Script {
    using TypeCasts for address;

    function run() public {
        uint256 payGasFees = 0.25 ether; // APE

        uint256 nfrPrice = 0.00001 ether; // APE
        address recipient = 0x03C4ec8B83540Cc43769501fB47f4F35a24cE568;
        address payable hypNativeToken = payable(0x9f58ec7e9B81b5401D4897E986CC372244D94A81);

        vm.startBroadcast();
        EspHypNative hyperlaneNativeToken = EspHypNative(hypNativeToken);

        hyperlaneNativeToken.initiateCrossChainNftPurchase{value: payGasFees + nfrPrice}(recipient.addressToBytes32());
        vm.stopBroadcast();
    }
}
