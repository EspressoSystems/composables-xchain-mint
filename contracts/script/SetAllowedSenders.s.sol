// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import "../src/EspressoEscrow.sol";

contract SetAllowedSendersScript is Script, Test, HyperlaneAddressesConfig {
    function run() public {
        address allowedSenderAddress = vm.envAddress("ALLOWED_SENDER_ADDRESS");
        address espressoEscrowAddress = vm.envAddress("ESPRESSO_ESCROW_ADDRESS");

        EspressoEscrow espressoEscrow = EspressoEscrow(espressoEscrowAddress);
        vm.startBroadcast();
        espressoEscrow.addAllowedSender(_addressToBytes32(allowedSenderAddress));
        vm.stopBroadcast();
    }

    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
