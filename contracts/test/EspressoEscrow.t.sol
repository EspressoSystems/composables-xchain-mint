pragma solidity 0.8.30;

import {Test, console} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {Mailbox} from "@hyperlane-core/solidity/contracts/Mailbox.sol";
import {IInterchainSecurityModule} from "@hyperlane-core/solidity/contracts/interfaces/IInterchainSecurityModule.sol";
import {
    StaticMessageIdMultisigIsmFactory,
    StaticMessageIdMultisigIsm
} from "@hyperlane-core/solidity/contracts/isms/multisig/StaticMultisigIsm.sol";

import "../src/EspressoEscrow.sol";

contract EspressoEscrowTest is Test, HyperlaneAddressesConfig {
    uint256 sourceChain;
    uint256 destinationChain;

    address mailBoxOwner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address baseEspressoTeeVerifier = makeAddr(string(abi.encode(1)));

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
    }

    /**
     * @dev Test checks that it returns valid local domain from Mailbox contracts on 2 different chains
     */
    function testSourceXChainMint() public {
        uint256 payGasFees = 0.1 ether;
        vm.selectFork(sourceChain);
        EspressoEscrow espressoEscrow = EspressoEscrow(payable(0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44));
        espressoEscrow.xChainMint{value: payGasFees}(uint32(31338), 0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44);
    }
}
