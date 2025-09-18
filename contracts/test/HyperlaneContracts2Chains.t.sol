pragma solidity 0.8.30;

import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {Mailbox} from "@hyperlane-core/solidity/contracts/Mailbox.sol";
import {IInterchainSecurityModule} from "@hyperlane-core/solidity/contracts/interfaces/IInterchainSecurityModule.sol";
import {
    StaticMessageIdMultisigIsmFactory,
    StaticMessageIdMultisigIsm
} from "@hyperlane-core/solidity/contracts/isms/multisig/StaticMultisigIsm.sol";

contract HyperlaneContracts2ChainsTest is Test, HyperlaneAddressesConfig {
    uint256 sourceChain;
    uint256 destinationChain;

    address mailBoxOwner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address baseEspressoTeeVerifier = makeAddr(string(abi.encode(1)));

    // Temporary using fake address to pass isAddress() validation
    address ismEspressoTEEVerifierSource = HyperlaneAddressesConfig.sourceConfig.mailbox;
    address ismEspressoTEEVerifierDestination = HyperlaneAddressesConfig.destinationConfig.mailbox;

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
    }

    /**
     * @dev Test checks that it returns valid local domain from Mailbox contracts on 2 different chains
     */
    function testGetLocalDomainOnMailbox2Chains() public {
        vm.selectFork(sourceChain);
        Mailbox sourceMailbox = Mailbox(sourceConfig.mailbox);

        assertEq(sourceMailbox.localDomain(), 412346);

        vm.selectFork(destinationChain);
        Mailbox destinationMailbox = Mailbox(destinationConfig.mailbox);

        assertEq(destinationMailbox.localDomain(), 31338);
    }

    function testSetDefaultIsmOnSourceMailbox() public {
        vm.selectFork(sourceChain);
        Mailbox sourceMailbox = Mailbox(sourceConfig.mailbox);

        assertNotEq(address(sourceMailbox.defaultIsm()), ismEspressoTEEVerifierSource);

        vm.prank(mailBoxOwner);
        sourceMailbox.setDefaultIsm(ismEspressoTEEVerifierSource);

        assertEq(address(sourceMailbox.defaultIsm()), ismEspressoTEEVerifierSource);
    }

    function testSetDefaultIsmOnDestinationMailbox() public {
        vm.selectFork(destinationChain);
        Mailbox destinationMailbox = Mailbox(destinationConfig.mailbox);

        assertNotEq(address(destinationMailbox.defaultIsm()), ismEspressoTEEVerifierDestination);

        vm.prank(mailBoxOwner);
        destinationMailbox.setDefaultIsm(ismEspressoTEEVerifierDestination);

        assertEq(address(destinationMailbox.defaultIsm()), ismEspressoTEEVerifierDestination);
    }

    /**
     * @dev Test deploys new StaticMessageIdMultisigIsm, updates DefaultISM on source chain, Mailbox copntract, checks that modelType is updated
     * and multisig ISM requires 1/1 validator signature.
     */
    // function testUpdateDefaultISMToStaticMessageIdMultisigISM() public {
    //     vm.selectFork(sourceChain);
    //     StaticMessageIdMultisigIsmFactory multisigIsmFactory =
    //         StaticMessageIdMultisigIsmFactory(sourceConfig.staticMessageIdMultisigIsmFactory);

    //     address validatorAddress = vm.envAddress("VALIDATOR_ADDRESS");

    //     address[] memory values = wrapAddress(validatorAddress);
    //     StaticMessageIdMultisigIsm messageIdMultisigIsm =
    //         StaticMessageIdMultisigIsm(multisigIsmFactory.deploy(values, uint8(values.length)));

    //     Mailbox sourceMailbox = Mailbox(sourceConfig.mailbox);
    //     vm.prank(mailBoxOwner);
    //     sourceMailbox.setDefaultIsm(address(messageIdMultisigIsm));

    //     assertEq(address(sourceMailbox.defaultIsm()), address(messageIdMultisigIsm));

    //     assertEq(messageIdMultisigIsm.moduleType(), uint8(IInterchainSecurityModule.Types.MESSAGE_ID_MULTISIG));

    //     bytes memory data = hex"00";
    //     (address[] memory validators, uint8 threshold) = messageIdMultisigIsm.validatorsAndThreshold(data);

    //     assertEq(validators[0], address(validatorAddress));
    //     assertEq(validators.length, 1);
    //     assertEq(threshold, uint8(1));
    // }

    function wrapAddress(address _addr) public pure returns (address[] memory) {
        address[] memory array = new address[](1);
        array[0] = _addr;
        return array;
    }
}
