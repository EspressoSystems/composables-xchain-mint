// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";
import "../src/EspressoEscrow.sol";

contract SetAllowedSendersScript is Script, Test, HyperlaneAddressesConfig {
    using TypeCasts for address;
    
    function run() public {
        address allowedSenderAddress = vm.envAddress("ALLOWED_SENDER_ADDRESS");
        address payable espressoEscrowAddress = payable(vm.envAddress("ESPRESSO_ESCROW_ADDRESS"));

        EspressoEscrow espressoEscrow = EspressoEscrow(espressoEscrowAddress);
        vm.startBroadcast();
        espressoEscrow.addAllowedSender(allowedSenderAddress.addressToBytes32());
        vm.stopBroadcast();
    }
}
