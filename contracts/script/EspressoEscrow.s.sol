// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import "../src/EspressoEscrow.sol";
import "../src/mocks/MockERC721.sol";

contract EspressoEscrowScript is Script, Test, HyperlaneAddressesConfig {
    function run() public {
        address mailboxAddress = vm.envAddress("MAILBOX_ADDRESS");
        address ismEspressoTEEVerifier = vm.envAddress("ISM_ADDRESS");
        uint32 originChainId = uint32(vm.envUint("ORIGIN_CHAIN_ID"));
        uint32 destinationChainId = uint32(vm.envUint("DESTINATION_CHAIN_ID"));

        vm.startBroadcast();
        address nft = address(new MockERC721());
        new EspressoEscrow(mailboxAddress, originChainId, destinationChainId, ismEspressoTEEVerifier, nft);
        vm.stopBroadcast();

        console.log("Mock ERC721: ");
        console.log(nft);
    }
}
