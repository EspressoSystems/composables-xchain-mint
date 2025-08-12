pragma solidity 0.8.30;

import {Test, console} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {Mailbox} from "@hyperlane-core/solidity/contracts/Mailbox.sol";
import {HypNative} from "@hyperlane-core/solidity/contracts/token/HypNative.sol";

import "../src/mocks/MockERC721.sol";

contract EspressoEscrowTest is Test, HyperlaneAddressesConfig {
    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = uint32(31338);

    address public deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public recipient = address(1);
    address public hypNativeTokenAddress = 0x7a2088a1bFc9d81c55368AE168C2C02570cB814F;

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
        uint amount = 0.2 ether;
        vm.selectFork(sourceChain);
        HypNative hypNativeToken = HypNative(payable(hypNativeTokenAddress));
        vm.deal(deployer, 1 ether);

        uint256 lockedNativeAssetsBefore = hypNativeToken.balanceOf(address(hypNativeToken));

        vm.prank(deployer);
        hypNativeToken.transferRemote{value: payGasFees + amount}(destinationChainId, _addressToBytes32(recipient), amount);

        assertEq(hypNativeToken.balanceOf(address(hypNativeToken)), lockedNativeAssetsBefore + amount);
    }

    /**
     * @dev Test checks that source chain part send native hyp tokens succeed
     */
    function testXChainSendNativeFailWhenSendWithoutGasFees() public {
        uint amount = 0.2 ether;
        vm.selectFork(sourceChain);
        HypNative hypNativeToken = HypNative(payable(hypNativeTokenAddress));
        vm.deal(deployer, 1 ether);


        vm.prank(deployer);
        vm.expectRevert(bytes("IGP: insufficient interchain gas payment"));
        hypNativeToken.transferRemote{value: amount}(destinationChainId, _addressToBytes32(recipient), amount);

    }

    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
