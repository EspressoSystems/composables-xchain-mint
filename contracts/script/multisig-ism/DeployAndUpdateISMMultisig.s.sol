// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../../script/configs/HyperlaneAddressesConfig.sol";
import {Mailbox} from "@hyperlane-core/solidity/contracts/Mailbox.sol";
import {IInterchainSecurityModule} from "@hyperlane-core/solidity/contracts/interfaces/IInterchainSecurityModule.sol";
import {StaticMessageIdMultisigIsmFactory} from "@hyperlane-core/solidity/contracts/isms/multisig/StaticMultisigIsm.sol";

contract DeployAndUpdateISMMultisigScript is Script, Test, HyperlaneAddressesConfig {
    function run() public {
        StaticMessageIdMultisigIsmFactory multisigIsmFactory =
            StaticMessageIdMultisigIsmFactory(sourceConfig.staticMessageIdMultisigIsmFactory);

        address validatorAddress = vm.envAddress("VALIDATOR_ADDRESS");

        address[] memory values = wrapAddress(validatorAddress);

        vm.startBroadcast();
        address messageIdMultisigIsm = multisigIsmFactory.deploy(values, uint8(values.length));

        Mailbox mailbox = Mailbox(sourceConfig.mailbox);

        mailbox.setDefaultIsm(messageIdMultisigIsm);

        vm.stopBroadcast();

        console.log("messageIdMultisigIsm: ");
        console.log(messageIdMultisigIsm);
        console.log("validatorAddress: ");
        console.log(validatorAddress);
    }

    function wrapAddress(address _addr) public pure returns (address[] memory) {
        address[] memory array = new address[](1);
        array[0] = _addr;
        return array;
    }
}
