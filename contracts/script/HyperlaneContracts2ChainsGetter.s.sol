// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {Mailbox} from "@hyperlane-core/solidity/contracts/Mailbox.sol";

contract HyperlaneContracts2ChainsGetterScript is Script, Test, HyperlaneAddressesConfig {

    function setUp() public {}

    function run() public {
        uint256 sourceChain = vm.createFork(vm.rpcUrl("source"));
        uint256 destinationChain = vm.createFork(vm.rpcUrl("destination"));

        vm.selectFork(sourceChain);
        Mailbox sourceMailbox = Mailbox(sourceConfig.mailbox);
        console.log("Source mailbox localDomain:", sourceMailbox.localDomain()); //
        assertEq(sourceMailbox.localDomain(), 412346);

        vm.selectFork(destinationChain);
        Mailbox destinationMailbox = Mailbox(destinationConfig.mailbox);
        console.log("Destination mailbox localDomain:", destinationMailbox.localDomain()); //
        assertEq(destinationMailbox.localDomain(), 31338);

    }
}
