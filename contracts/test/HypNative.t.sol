pragma solidity 0.8.30;

import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";

import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";
import {Mailbox} from "@hyperlane-core/solidity/contracts/Mailbox.sol";
import {EspHypNative} from "../src/EspHypNative.sol";

import "../src/mocks/MockERC721.sol";

contract HypNativeTest is Test, HyperlaneAddressesConfig {
    using TypeCasts for address;

    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = uint32(31338);

    address public deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public recipient = address(1);
    address public hypNativeTokenAddress = 0x09635F643e140090A9A8Dcd712eD6285858ceBef;

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
    }

    receive() external payable {}

    /**
     * @dev Test checks that source chain part send native hyp tokens succeed
     */
    function testXChainSendNativeTokensSourcePart() public {
        uint256 payGasFees = 0.001 ether;
        uint256 amount = 0.1 ether;
        vm.selectFork(sourceChain);
        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));
        vm.deal(deployer, 1 ether);

        uint256 lockedNativeAssetsBefore = hypNativeToken.balanceOf(address(hypNativeToken));

        vm.prank(deployer);
        hypNativeToken.initiateCrossChainNftPurchase{value: payGasFees + amount}(recipient.addressToBytes32(), amount);

        assertEq(hypNativeToken.balanceOf(address(hypNativeToken)), lockedNativeAssetsBefore + amount);
    }

    /**
     * @dev Test checks that source chain part send native hyp tokens succeed
     */
    function testXChainSendNativeFailWhenSendWithoutGasFees() public {
        uint256 amount = 0.1 ether;
        vm.selectFork(sourceChain);
        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));
        vm.deal(deployer, 1 ether);

        vm.prank(deployer);
        vm.expectRevert(bytes("IGP: insufficient interchain gas payment"));
        hypNativeToken.initiateCrossChainNftPurchase{value: amount}(recipient.addressToBytes32(), amount);
    }

    /**
     * @dev Test checks that hyperlane external function transferRemote is reverted when called by the caller.
     */
    function testRevertTransferRemoteOnEspHypNative() public {
        uint256 payGasFees = 0.001 ether;
        uint256 amount = 0.1 ether;
        vm.selectFork(sourceChain);
        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));
        vm.deal(deployer, 1 ether);

        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(EspHypNative.UseInitiateCrossChainNftPurchaseFunction.selector));
        hypNativeToken.transferRemote{value: payGasFees + amount}(
            destinationChainId, recipient.addressToBytes32(), amount
        );
    }

    /**
     * @dev Test checks that hyperlane external function transferRemote with hooks params is reverted when called by the caller.
     */
    function testRevertTransferRemoteWithHookParamsOnEspHypNative() public {
        uint256 payGasFees = 0.001 ether;
        uint256 amount = 0.1 ether;
        vm.selectFork(sourceChain);
        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));
        vm.deal(deployer, 1 ether);

        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(EspHypNative.UseInitiateCrossChainNftPurchaseFunction.selector));
        hypNativeToken.transferRemote{value: payGasFees + amount}(
            destinationChainId, recipient.addressToBytes32(), amount, bytes(""), address(1)
        );
    }

    /**
     * @dev Test checks that cross chain NFT purchase reverted if caller set NFT price less than expected NFT price.
     */
    function testRevertInitiateCrossChainNftPurchaseAmountLessThanNftPrice() public {
        uint256 payGasFees = 0.001 ether;
        uint256 nftPrice = 0.1 ether;
        uint256 amount = 0.009 ether;
        vm.selectFork(sourceChain);
        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));
        vm.deal(deployer, 1 ether);

        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(EspHypNative.WrongNftPriceProvided.selector, amount, nftPrice));
        hypNativeToken.initiateCrossChainNftPurchase{value: payGasFees + amount}(recipient.addressToBytes32(), amount);
    }

    /**
     * @dev Test checks that cross chain NFT purchase reverted if caller set NFT price more than expected NFT price.
     */
    function testRevertInitiateCrossChainNftPurchaseAmountMoreThanNftPrice() public {
        uint256 payGasFees = 0.001 ether;
        uint256 nftPrice = 0.1 ether;
        uint256 amount = 0.101 ether;
        vm.selectFork(sourceChain);
        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));
        vm.deal(deployer, 1 ether);

        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(EspHypNative.WrongNftPriceProvided.selector, amount, nftPrice));
        hypNativeToken.initiateCrossChainNftPurchase{value: payGasFees + amount}(recipient.addressToBytes32(), amount);
    }

    /**
     * @dev Test checks that cross chain NFT purchase reverted if caller set amount more then msg.value.
     */
    function testRevertInitiateCrossChainNftPurchaseAmountMoreThanMsgValue() public {
        uint256 amount = 0.1 ether;
        vm.selectFork(sourceChain);
        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));
        vm.deal(deployer, 1 ether);

        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(EspHypNative.AmountExceedsMsgValue.selector, amount, amount - 1 wei));
        hypNativeToken.initiateCrossChainNftPurchase{value: amount - 1 wei}(recipient.addressToBytes32(), amount);
    }
}
