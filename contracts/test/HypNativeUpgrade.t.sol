pragma solidity 0.8.30;

import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {HypNative} from "@hyperlane-core/solidity/contracts/token/HypNative.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";

import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../src/mocks/MockERC721.sol";
import {EspHypNative} from "../src/EspHypNative.sol";

contract HypNativeUpgradeTest is Test, HyperlaneAddressesConfig {
    using TypeCasts for address;

    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = uint32(31338);

    address public proxyAdminOwner = espSourceConfig.deployer;
    address public notProxyAdminOwner = makeAddr(string(abi.encode(1)));
    address public recipient = makeAddr(string(abi.encode(2)));
    address public hypNativeTokenAddress = espSourceConfig.sourceToDestinationEspTokenProxy;
    address public hypNativeTokenImplementationAddress = espSourceConfig.sourceToDestinationEspTokenImplementation;

    ITransparentUpgradeableProxy public hypNativeProxy;
    ProxyAdmin public proxyAdmin;

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
        vm.selectFork(sourceChain);
        hypNativeProxy = ITransparentUpgradeableProxy(hypNativeTokenAddress);
        proxyAdmin = ProxyAdmin(sourceConfig.proxyAdmin);
    }

    /**
     * @dev Test checks that it is allowed to get native token proxy admin
     */
    function testGetHypNativeProxyAdminAddress() public view {
        assertEq(proxyAdmin.getProxyAdmin(hypNativeProxy), address(proxyAdmin));
    }

    /**
     * @dev Test checks that it is allowed to get native token implementation
     */
    function testGetHypNativeImplementationAddress() public view {
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

        EspHypNative espressoNativeTokenImplementation = new EspHypNative(initialScale, sourceConfig.mailbox);

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

        EspHypNative espressoNativeTokenImplementation = new EspHypNative(initialScale, sourceConfig.mailbox);

        vm.prank(notProxyAdminOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        proxyAdmin.upgrade(hypNativeProxy, address(espressoNativeTokenImplementation));
    }

    /**
     * @dev Test checks that source chain part send native hyp tokens succeed with upgraded contract and initiateCrossChainNftPurchase function
     */
    function testXChainSendNativeTokensSourcePartWithUpgradedEspressoToken() public {
        uint256 payGasFees = 0.001 ether;
        uint256 amount = 0.1 ether;
        vm.selectFork(sourceChain);
        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));

        EspHypNative espressoNativeTokenImplementation = new EspHypNative(1, sourceConfig.mailbox);

        assertEq(proxyAdmin.getProxyImplementation(hypNativeProxy), hypNativeTokenImplementationAddress);

        vm.prank(proxyAdminOwner);
        proxyAdmin.upgrade(hypNativeProxy, address(espressoNativeTokenImplementation));

        vm.deal(proxyAdminOwner, 1 ether);

        uint256 lockedNativeAssetsBefore = hypNativeToken.balanceOf(address(hypNativeToken));

        vm.prank(proxyAdminOwner);
        hypNativeToken.initiateCrossChainNftPurchase{value: payGasFees + amount}(recipient.addressToBytes32());

        assertEq(hypNativeToken.balanceOf(address(hypNativeToken)), lockedNativeAssetsBefore + amount);
    }

    /**
     * @dev Test checks that nobody is able to call .initializeV2() function after the proxy upgrade.
     */
    function testChecksEspressoNativeTokenInitializeV2NotExecutable() public {
        EspHypNative hypNativeToken = EspHypNative(payable(hypNativeTokenAddress));

        vm.prank(proxyAdminOwner);
        vm.expectRevert(bytes("Initializable: contract is already initialized"));
        hypNativeToken.initializeV2(1, 1);
    }

    receive() external payable {}
}
