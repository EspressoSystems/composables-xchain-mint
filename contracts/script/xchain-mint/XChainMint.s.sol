// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../../script/configs/HyperlaneAddressesConfig.sol";
import "../../src/EspressoEscrow.sol";

contract XChainMintScript is Script, Test, HyperlaneAddressesConfig {
    function run() public {
        uint256 payGasFees = 0.1 ether;

        address payable sEspressoEscrowAddress = payable(vm.envAddress("SOURCE_ESPRESSO_ESCROW_ADDRESS"));
        uint32 sourceDestinationChainId = uint32(vm.envUint("DESTINATION_CHAIN_ID"));
        address payable destinationEspressoEscrowAddress = payable(vm.envAddress("DESTINATION_ESPRESSO_ESCROW_ADDRESS"));

        vm.startBroadcast();
        EspressoEscrow espressoEscrow = EspressoEscrow(sEspressoEscrowAddress);
        espressoEscrow.xChainMint{value: payGasFees}(sourceDestinationChainId, destinationEspressoEscrowAddress);
        vm.stopBroadcast();
    }
}
