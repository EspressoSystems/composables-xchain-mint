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
import "../src/mocks/MockERC721.sol";

contract EspressoEscrowTest is Test, HyperlaneAddressesConfig {
    uint256 sourceChain;
    uint256 destinationChain;

    address public deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public baseEspressoTeeVerifier = makeAddr(string(abi.encode(1)));
    address public mailboxAddress = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;
    address public espressoEscrowAddress = 0x4A679253410272dd5232B3Ff7cF5dbB88f295319;
    address public nftAddress = 0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f;

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
    }

    /**
     * @dev Test checks that source chain part xchainmint succeed
     */
    function testXChainMintSourcePart() public {
        uint256 payGasFees = 0.1 ether;
        vm.selectFork(sourceChain);
        EspressoEscrow espressoEscrow = EspressoEscrow(payable(espressoEscrowAddress));
        espressoEscrow.xChainMint{value: payGasFees}(uint32(31338), espressoEscrowAddress);
    }

    /**
     * @dev Test checks that destination chain part xchainmint succeed
     */
    function testXChainMintDestinationPart() public {
        vm.selectFork(destinationChain);

        MockERC721 nft = MockERC721(nftAddress);
        uint256 tokensCount = nft.nextTokenId();
        assertEq(nft.nextTokenId(), tokensCount);
        EspressoEscrow espressoEscrow = EspressoEscrow(payable(espressoEscrowAddress));

        bytes memory data = abi.encodeWithSelector(MockERC721.mint.selector, deployer);

        vm.prank(mailboxAddress);
        espressoEscrow.handle(uint32(412346), _addressToBytes32(espressoEscrowAddress), data);

        assertEq(nft.nextTokenId(), tokensCount + 1);
    }

    /**
     * @dev Test checks refunds on espressoEscrow contract.
     */
    function testCheckGasPaymasterRefund() public {
        vm.selectFork(sourceChain);
        EspressoEscrow espressoEscrow = EspressoEscrow(payable(espressoEscrowAddress));

        uint256 balance = address(espressoEscrow).balance;
        assertNotEq(balance, 0);
    }

    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
