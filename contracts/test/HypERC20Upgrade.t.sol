pragma solidity 0.8.30;

import {Test, console} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {Mailbox} from "@hyperlane-core/solidity/contracts/Mailbox.sol";
import {HypERC20} from "@hyperlane-core/solidity/contracts/token/HypERC20.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";

import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";


import "../src/mocks/MockERC721.sol";
import "../src/EspressoERC20.sol";


contract HypERC20UpgradeTest is Test, HyperlaneAddressesConfig {
    using TypeCasts for address;
    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = uint32(31338);
    uint8 public decimals = 18;

    address public proxyAdminOwner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public notProxyAdminOwner = makeAddr(string(abi.encode(1)));
    address public recipient = makeAddr(string(abi.encode(2)));
    address public treasuryAddress = payable(makeAddr(string(abi.encode(3))));
    address public marketplaceAddress = makeAddr(string(abi.encode(4)));
    address public hypERC20TokenAddress = 0x7a2088a1bFc9d81c55368AE168C2C02570cB814F;
    address public hypERC20ImplementationAddress = 0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f;

    ITransparentUpgradeableProxy public hypERC20Proxy;
    ProxyAdmin public proxyAdmin;

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
        vm.selectFork(destinationChain);
        hypERC20Proxy = ITransparentUpgradeableProxy(hypERC20TokenAddress);
        proxyAdmin = ProxyAdmin(HyperlaneAddressesConfig.destinationConfig.proxyAdmin);
    }

    /**
     * @dev Test checks that it is allowed to get synthetic token proxy admin
     */
    function testGetHypERC20ProxyAdminAddress() view public {
        assertEq(proxyAdmin.getProxyAdmin(hypERC20Proxy), address(proxyAdmin));
    }

    /**
     * @dev Test checks that it is allowed to get synthetic token implementation
     */
    function testGetHypERC20ImplementationAddress() view public {
        assertEq(proxyAdmin.getProxyImplementation(hypERC20Proxy), hypERC20ImplementationAddress);
    }

    /**
     * @dev Test checks that owner of proxy admin contract is able to upgrade hyp synthetic proxy with the new implementation version.
     */
    function testChecksHypERC20nUpgradeFunctionality() public {
        vm.selectFork(destinationChain);
        HypERC20 hypERC20Token = HypERC20(payable(hypERC20TokenAddress));

        // We will use scale equal 1 in all new token implementations, we would have same decimals on chains
        uint256 initialScale = hypERC20Token.scale();
        assertEq(initialScale, 1);

        EspressoERC20 espressoERC20Implementation = new EspressoERC20(decimals, initialScale, HyperlaneAddressesConfig.destinationConfig.mailbox);


        assertEq(proxyAdmin.getProxyImplementation(hypERC20Proxy), hypERC20ImplementationAddress);

        vm.prank(proxyAdminOwner);
        proxyAdmin.upgrade(hypERC20Proxy, address(espressoERC20Implementation));

        assertEq(proxyAdmin.getProxyImplementation(hypERC20Proxy), address(espressoERC20Implementation));

        EspressoERC20 espressoERC20Token = EspressoERC20(payable(hypERC20TokenAddress));

        assertEq(espressoERC20Token.rariMarketplace(), address(0));
        assertEq(address(espressoERC20Token.treasury()), address(0));
    }

    /**
     * @dev Test checks that owner of proxy admin contract is able to upgrade hyp synthetic proxy with the new implementation and execute transaction via .upgradeAndCall()
     */
    function testChecksHypERC20nUpgradeAndCallFunctionality() public {
        vm.selectFork(destinationChain);
        HypERC20 hypERC20Token = HypERC20(payable(hypERC20TokenAddress));

        uint256 initialScale = hypERC20Token.scale();
        assertEq(initialScale, 1);

        EspressoERC20 espressoERC20Implementation = new EspressoERC20(decimals, initialScale, HyperlaneAddressesConfig.destinationConfig.mailbox);


        assertEq(proxyAdmin.getProxyImplementation(hypERC20Proxy), hypERC20ImplementationAddress);

        vm.prank(proxyAdminOwner);
        bytes memory setupData = abi.encodeWithSelector(EspressoERC20.setUp.selector, marketplaceAddress, treasuryAddress);
        EspressoERC20 espressoERC20Token = EspressoERC20(payable(hypERC20TokenAddress));

        proxyAdmin.upgradeAndCall(hypERC20Proxy, address(espressoERC20Implementation), setupData);

        assertEq(proxyAdmin.getProxyImplementation(hypERC20Proxy), address(espressoERC20Implementation));
        assertEq(espressoERC20Token.rariMarketplace(), marketplaceAddress);
        assertEq(address(espressoERC20Token.treasury()), treasuryAddress);

    }

    /**
     * @dev Test checks that nobody is able to call .setUp() functiuon after the proxy upgrade.
     */
    function testChecksEspressoERC20SetUpNotExecutable() public {
        testChecksHypERC20nUpgradeAndCallFunctionality();

        EspressoERC20 espressoERC20Token = EspressoERC20(payable(hypERC20TokenAddress));

        vm.prank(proxyAdminOwner);
        vm.expectRevert(
            abi.encodeWithSelector(EspressoERC20.EspressoERC20Initiated.selector)
        );
        espressoERC20Token.setUp(address(1), payable(address(2)));
    }

    /**
     * @dev Test checks that not owner of proxy admin contract is NOT able to upgrade hyp synthetic proxy;
     */
    function testNotOwnerHypERC20Upgrade() public {
        vm.selectFork(destinationChain);
        HypERC20 hypERC20Token = HypERC20(payable(hypERC20TokenAddress));

        uint256 initialScale = hypERC20Token.scale();

        EspressoERC20 espressoERC20Implementation = new EspressoERC20(decimals, initialScale, HyperlaneAddressesConfig.destinationConfig.mailbox);

        vm.prank(notProxyAdminOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        proxyAdmin.upgrade(hypERC20Proxy, address(espressoERC20Implementation));
    }

        /**
     * @dev Test checks that not owner of proxy admin contract is NOT able to upgrade and call hyp synthetic proxy;
     */
    function testNotOwnerHypERC20UpgradeAndCall() public {
        vm.selectFork(destinationChain);
        HypERC20 hypERC20Token = HypERC20(payable(hypERC20TokenAddress));

        uint256 initialScale = hypERC20Token.scale();

        EspressoERC20 espressoERC20Implementation = new EspressoERC20(decimals, initialScale, HyperlaneAddressesConfig.destinationConfig.mailbox);

        vm.prank(notProxyAdminOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        proxyAdmin.upgradeAndCall(hypERC20Proxy, address(espressoERC20Implementation), '');
    }

    receive() external payable {}
}
