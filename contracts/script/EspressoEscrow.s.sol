// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {Mailbox} from "@hyperlane-core/solidity/contracts/Mailbox.sol";
import {IInterchainSecurityModule} from "@hyperlane-core/solidity/contracts/interfaces/IInterchainSecurityModule.sol";
import {
    StaticMessageIdMultisigIsmFactory,
    StaticMessageIdMultisigIsm
} from "@hyperlane-core/solidity/contracts/isms/multisig/StaticMultisigIsm.sol";
import "../src/EspressoEscrow.sol";

contract EspressoEscrowScript is Script, Test, HyperlaneAddressesConfig {
    function run() public {
        address mailboxAddress = vm.envAddress("MAILBOX_ADDRESS");
        address ismEspressoTEEVerifier = vm.envAddress("ISM_ADDRESS");
        address rariMarketplace = vm.envAddress("RARI_ADDRESS");
        uint32 originChainId = uint32(vm.envUint("ORIGIN_CHAIN_ID"));
        uint32 destinationChainId = uint32(vm.envUint("DESTINATION_CHAIN_ID"));

        vm.startBroadcast();
        new EspressoEscrow(mailboxAddress, originChainId, destinationChainId, ismEspressoTEEVerifier, rariMarketplace);
        vm.stopBroadcast();
    }
}
