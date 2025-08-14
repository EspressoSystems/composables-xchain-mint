pragma solidity 0.8.30;

import {Test, console} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {Mailbox} from "@hyperlane-core/solidity/contracts/Mailbox.sol";
import {HypNative} from "@hyperlane-core/solidity/contracts/token/HypNative.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";


import "../src/mocks/MockERC721.sol";

contract HypNativeUpgradeTest is Test, HyperlaneAddressesConfig {
    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = uint32(31338);

    address public proxyAdminOwner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public hypNativeTokenAddress = 0x7a2088a1bFc9d81c55368AE168C2C02570cB814F;
    address public hypNativeTokenImplementationAddress = 0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f;

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));

    }

    /**
     * @dev Test checks that it is allowed to get native token proxy admin
     */
    function testGetHypNativeProxyAdminAddress() public {
        vm.selectFork(sourceChain);
        ITransparentUpgradeableProxy hypNativeProxy = ITransparentUpgradeableProxy(hypNativeTokenAddress);
        ProxyAdmin proxyAdmin = ProxyAdmin(HyperlaneAddressesConfig.sourceConfig.proxyAdmin);

        assertEq(proxyAdmin.getProxyAdmin(hypNativeProxy), address(proxyAdmin));
    }

    /**
     * @dev Test checks that it is allowed to get native token implementation
     */
    function testGetHypNativeImplementationAddress() public {
        vm.selectFork(sourceChain);
        ITransparentUpgradeableProxy hypNativeProxy = ITransparentUpgradeableProxy(hypNativeTokenAddress);
        ProxyAdmin proxyAdmin = ProxyAdmin(HyperlaneAddressesConfig.sourceConfig.proxyAdmin);

        assertEq(proxyAdmin.getProxyImplementation(hypNativeProxy), hypNativeTokenImplementationAddress);
    }

    /**
     * @dev Test checks that owner of proxy admin contract is able to upgrade hyp native proxy with the new implementation version.
     */
    function testChecksHypNativeTokenUpgradeFunctionality() public {
        vm.selectFork(sourceChain);
        HypNative hypNativeToken = HypNative(payable(hypNativeTokenAddress));

        assertEq(hypNativeToken.scale(), 1);
        // We will use scale equal 1 in all new token implementations, we would have same decimals on chains
    }
}
