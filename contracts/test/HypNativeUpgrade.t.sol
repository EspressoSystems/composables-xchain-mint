pragma solidity 0.8.30;

import {Test, console} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {Mailbox} from "@hyperlane-core/solidity/contracts/Mailbox.sol";
import {HypNative} from "@hyperlane-core/solidity/contracts/token/HypNative.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";

import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";


import "../src/mocks/MockERC721.sol";
import "../src/EspressoNativeToken.sol";


contract HypNativeUpgradeTest is Test, HyperlaneAddressesConfig {
    using TypeCasts for address;
    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = uint32(31338);

    address public proxyAdminOwner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public notProxyAdminOwner = makeAddr(string(abi.encode(1)));
    address public recipient = makeAddr(string(abi.encode(2)));
    address public hypNativeTokenAddress = 0x7a2088a1bFc9d81c55368AE168C2C02570cB814F;
    address public hypNativeTokenImplementationAddress = 0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f;

    ITransparentUpgradeableProxy public hypNativeProxy;
    ProxyAdmin public proxyAdmin;

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
        vm.selectFork(sourceChain);
        hypNativeProxy = ITransparentUpgradeableProxy(hypNativeTokenAddress);
        proxyAdmin = ProxyAdmin(HyperlaneAddressesConfig.sourceConfig.proxyAdmin);

    }

    /**
     * @dev Test checks that it is allowed to get native token proxy admin
     */
    function testGetHypNativeProxyAdminAddress() view public {
        assertEq(proxyAdmin.getProxyAdmin(hypNativeProxy), address(proxyAdmin));
    }

    /**
     * @dev Test checks that it is allowed to get native token implementation
     */
    function testGetHypNativeImplementationAddress() view public {
        assertEq(proxyAdmin.getProxyImplementation(hypNativeProxy), hypNativeTokenImplementationAddress);
    }

    /**
     * @dev Test checks that owner of proxy admin contract is able to upgrade hyp native proxy with the new implementation version.
     */
    function testChecksHypNativeTokenUpgradeFunctionality() public {
        vm.selectFork(sourceChain);
        HypNative hypNativeToken = HypNative(payable(hypNativeTokenAddress));

        // We will use scale equal 1 in all new token implementations, we would have same decimals on chains
        uint256 initialScale = hypNativeToken.scale();
        assertEq(initialScale, 1);

        EspressoNativeToken espressoNativeTokenImplementation = new EspressoNativeToken(initialScale, HyperlaneAddressesConfig.sourceConfig.mailbox);


        assertEq(proxyAdmin.getProxyImplementation(hypNativeProxy), hypNativeTokenImplementationAddress);

        vm.prank(proxyAdminOwner);
        proxyAdmin.upgrade(hypNativeProxy, address(espressoNativeTokenImplementation));

        assertEq(proxyAdmin.getProxyImplementation(hypNativeProxy), address(espressoNativeTokenImplementation));
    }

    /**
     * @dev Test checks that not owner of proxy admin contract is NOT able to upgrade hyp native proxy;
     */
    function testNotOwnerHypNativeUpgrade() public {
        vm.selectFork(sourceChain);
        HypNative hypNativeToken = HypNative(payable(hypNativeTokenAddress));

        uint256 initialScale = hypNativeToken.scale();

        EspressoNativeToken espressoNativeTokenImplementation = new EspressoNativeToken(initialScale, HyperlaneAddressesConfig.sourceConfig.mailbox);

        vm.prank(notProxyAdminOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        proxyAdmin.upgrade(hypNativeProxy, address(espressoNativeTokenImplementation));
    }

    /**
     * @dev Test checks that source chain part send native hyp tokens succeed with upgraded contract and old transferRemote function
     */
    function testXChainSendNativeTokensSourcePartWithUpgradedEspressoToken() public {
        uint256 payGasFees = 0.001 ether;
        uint amount = 0.2 ether;
        vm.selectFork(sourceChain);
        HypNative hypNativeToken = HypNative(payable(hypNativeTokenAddress));

        EspressoNativeToken espressoNativeTokenImplementation = new EspressoNativeToken(1, HyperlaneAddressesConfig.sourceConfig.mailbox);


        assertEq(proxyAdmin.getProxyImplementation(hypNativeProxy), hypNativeTokenImplementationAddress);

        vm.prank(proxyAdminOwner);
        proxyAdmin.upgrade(hypNativeProxy, address(espressoNativeTokenImplementation));

        vm.deal(proxyAdminOwner, 1 ether);

        uint256 lockedNativeAssetsBefore = hypNativeToken.balanceOf(address(hypNativeToken));

        vm.prank(proxyAdminOwner);
        hypNativeToken.transferRemote{value: payGasFees + amount}(destinationChainId, recipient.addressToBytes32(), amount);

        assertEq(hypNativeToken.balanceOf(address(hypNativeToken)), lockedNativeAssetsBefore + amount);
    }

    /**
     * @dev Test checks that source chain part send native hyp tokens succeed with upgraded contract and new transferRemote function
     */
    function testXChainSendNativeTokensSourcePartWithUpgradedEspressoTokenFunction() public {
        uint256 payGasFees = 0.001 ether;
        uint amount = 0.2 ether;
        vm.selectFork(sourceChain);
        EspressoNativeToken espressoNativeToken = EspressoNativeToken(payable(hypNativeTokenAddress));

        EspressoNativeToken espressoNativeTokenImplementation = new EspressoNativeToken(1, HyperlaneAddressesConfig.sourceConfig.mailbox);


        assertEq(proxyAdmin.getProxyImplementation(hypNativeProxy), hypNativeTokenImplementationAddress);

        vm.prank(proxyAdminOwner);
        proxyAdmin.upgrade(hypNativeProxy, address(espressoNativeTokenImplementation));

        vm.deal(proxyAdminOwner, 1 ether);

        uint256 lockedNativeAssetsBefore = espressoNativeToken.balanceOf(address(espressoNativeToken));

        vm.prank(proxyAdminOwner);
        vm.expectEmit(true, true, true, true);
        emit EspressoNativeToken.TransaferOnUpgrade();
        espressoNativeToken.transferRemoteUpgrade{value: payGasFees + amount}(destinationChainId, recipient.addressToBytes32(), amount);

        assertEq(espressoNativeToken.balanceOf(address(espressoNativeToken)), lockedNativeAssetsBefore + amount);
    }

    receive() external payable {}
}
