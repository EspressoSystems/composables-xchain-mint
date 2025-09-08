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
    address public hypERC20TokenAddress = 0x09635F643e140090A9A8Dcd712eD6285858ceBef;
    address public hypERC20ImplementationAddress = 0x9E545E3C0baAB3E08CdfD552C960A1050f373042;

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
     * @dev Test checks that nobody is able to call .setUp() function after the proxy upgrade.
     */
    function testChecksEspressoERC20SetUpNotExecutable() public {

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
