// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import "../src/EspressoEscrow.sol";

contract XChainMintScript is Script, Test, HyperlaneAddressesConfig {
    function run() public {
        uint256 payGasFees = 0.1 ether;

        address payable sEspressoEscrowAddress = payable(vm.envAddress("S_ESPRESSO_ESCROW_ADDRESS"));
        uint32 sDestinationChainId = uint32(vm.envUint("S_DESTINATION_CHAIN_ID"));
        address payable dEspressoEscrowAddress = payable(vm.envAddress("D_ESPRESSO_ESCROW_ADDRESS"));

        vm.startBroadcast();
        EspressoEscrow espressoEscrow = EspressoEscrow(sEspressoEscrowAddress);
        espressoEscrow.xChainMint{value: payGasFees}(sDestinationChainId, dEspressoEscrowAddress);
        vm.stopBroadcast();
    }
}
