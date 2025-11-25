pragma solidity 0.8.30;

import {Test} from "forge-std/src/Test.sol";

import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";
import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {EspHypNative} from "../src/EspHypNative.sol";
import {SaleTimeAndPrice} from "../src/libs/SaleTimeAndPrice.sol";

contract HypNativeTest is Test, HyperlaneAddressesConfig {
    using TypeCasts for address;

    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = espSourceConfig.destinationChainId;
    uint256 public nftPrice = 0.001 ether;

    address public deployer = espSourceConfig.deployer;
    address public recipient = address(1);
    address public hypNativeTokenAddress = espSourceConfig.sourceToDestinationEspTokenProxy;
    uint256 public startSale = 1762790975;
    uint256 public endSale = startSale + 3 weeks;

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
        vm.warp(startSale);
    }

    receive() external payable {}

    /**
     * @dev Test checks that source chain part send native hyp tokens succeed
     */
    function testXChainSendNativeTokensSourcePart() public {
        uint256 payGasFees = 0.001 ether;
        uint256 amount = 0.001 ether;
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
        uint256 amount = 0.001 ether;
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
        uint256 amount = 0.001 ether;
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
        uint256 amount = 0.001 ether;
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
        uint256 amount = 0.001 ether;
        vm.selectFork(sourceChain);
        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));
        vm.deal(deployer, 1 ether);

        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(EspHypNative.NftPriceExceedsMsgValue.selector, amount, amount - 1));
        hypNativeToken.initiateCrossChainNftPurchase{value: amount - 1}(recipient.addressToBytes32());
    }

    /**
     * @dev Test checks that crosschain buy fail on initial initiateCrossChainNftPurchase step if sale not started.
     */
    function testXChainInitiateCrossChainNftPurchaseRevertBeforeSaleStart() public {
        uint256 payGasFees = 0.001 ether;
        uint256 amount = 0.001 ether;
        uint256 beforeSaleStart = startSale - 1;

        vm.selectFork(sourceChain);
        vm.warp(beforeSaleStart);

        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));

        vm.expectRevert(
            abi.encodeWithSelector(
                SaleTimeAndPrice.SaleFinishedOrNotStarted.selector, startSale, endSale, beforeSaleStart
            )
        );
        hypNativeToken.initiateCrossChainNftPurchase{value: payGasFees + amount}(recipient.addressToBytes32());
    }

    /**
     * @dev Test checks that crosschain buy fail on initial initiateCrossChainNftPurchase step if sale is finished.
     */
    function testXChainInitiateCrossChainNftPurchaseRevertWhenSaleFinished() public {
        uint256 payGasFees = 0.001 ether;
        uint256 amount = 0.001 ether;
        uint256 afterSaleEnd = endSale + 1;

        vm.selectFork(sourceChain);
        vm.warp(afterSaleEnd);

        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));

        vm.expectRevert(
            abi.encodeWithSelector(SaleTimeAndPrice.SaleFinishedOrNotStarted.selector, startSale, endSale, afterSaleEnd)
        );
        hypNativeToken.initiateCrossChainNftPurchase{value: payGasFees + amount}(recipient.addressToBytes32());
    }

    /**
     * @dev Test checks that Nft price updated and not valid for new purchases with old price
     */
    function testXChainInitiateCrossChainNftPurchaseRevertAfterUpdatingTheNftPrice() public {
        uint256 amount = 0.001 ether;
        uint256 newNftPrice = 0.0011 ether;
        vm.selectFork(sourceChain);
        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));

        vm.prank(deployer);
        hypNativeToken.setSalePrice(newNftPrice);

        vm.expectRevert(abi.encodeWithSelector(EspHypNative.NftPriceExceedsMsgValue.selector, newNftPrice, amount));
        hypNativeToken.initiateCrossChainNftPurchase{value: amount}(recipient.addressToBytes32());
    }
}
