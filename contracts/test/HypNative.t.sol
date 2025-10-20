pragma solidity 0.8.30;

import {Test} from "forge-std/src/Test.sol";

import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";
import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {EspHypNative} from "../src/EspHypNative.sol";

import "../src/mocks/MockERC721.sol";

contract HypNativeTest is Test, HyperlaneAddressesConfig {
    using TypeCasts for address;

    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = espSourceConfig.destinationChainId;
    uint256 public nftPrice = 0.1 ether;

    address public deployer = espSourceConfig.deployer;
    address public recipient = address(1);
    address public hypNativeTokenAddress = espSourceConfig.sourceToDestinationEspTokenProxy;

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
        hypNativeToken.initiateCrossChainNftPurchase{value: payGasFees + amount}(recipient.addressToBytes32());

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
        hypNativeToken.initiateCrossChainNftPurchase{value: amount}(recipient.addressToBytes32());
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
        vm.expectRevert(EspHypNative.UseInitiateCrossChainNftPurchaseFunction.selector);
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
        vm.expectRevert(EspHypNative.UseInitiateCrossChainNftPurchaseFunction.selector);
        hypNativeToken.transferRemote{value: payGasFees + amount}(
            destinationChainId, recipient.addressToBytes32(), amount, bytes(""), address(1)
        );
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
        vm.expectRevert(abi.encodeWithSelector(EspHypNative.NftPriceExceedsMsgValue.selector, amount, amount - 1 wei));
        hypNativeToken.initiateCrossChainNftPurchase{value: amount - 1 wei}(recipient.addressToBytes32());
    }
}
