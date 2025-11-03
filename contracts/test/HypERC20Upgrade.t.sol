pragma solidity 0.8.30;

import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../script/configs/HyperlaneAddressesConfig.sol";
import {HypERC20} from "@hyperlane-core/solidity/contracts/token/HypERC20.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";

import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../src/EspHypERC20.sol";
import "../src/libs/Treasury.sol";

contract HypERC20UpgradeTest is Test, HyperlaneAddressesConfig {
    using TypeCasts for address;

    uint256 public sourceChain;
    uint256 public destinationChain;
    uint32 public destinationChainId = espSourceConfig.destinationChainId;
    uint8 public decimals = 18;
    Treasury.TreasuryStruct public treasury = Treasury.TreasuryStruct(payable(address(1)), payable(address(2)), 100);

    address public proxyAdminOwner = espSourceConfig.deployer;
    address public notProxyAdminOwner = makeAddr(string(abi.encode(1)));
    address public recipient = makeAddr(string(abi.encode(2)));
    address public treasuryAddress = payable(makeAddr(string(abi.encode(3))));
    address public marketplaceAddress = makeAddr(string(abi.encode(4)));
    address public hypERC20TokenAddress = espDestinationConfig.sourceToDestinationEspTokenProxy;
    address public hypERC20ImplementationAddress = espDestinationConfig.sourceToDestinationEspTokenImplementation;

    ITransparentUpgradeableProxy public hypERC20Proxy;
    ProxyAdmin public proxyAdmin;

    function setUp() public {
        sourceChain = vm.createFork(vm.rpcUrl("source"));
        destinationChain = vm.createFork(vm.rpcUrl("destination"));
        vm.selectFork(destinationChain);
        hypERC20Proxy = ITransparentUpgradeableProxy(hypERC20TokenAddress);
        proxyAdmin = ProxyAdmin(destinationConfig.proxyAdmin);
    }

    /**
     * @dev Test checks that it is allowed to get synthetic token proxy admin
     */
    function testGetHypERC20ProxyAdminAddress() public view {
        assertEq(proxyAdmin.getProxyAdmin(hypERC20Proxy), address(proxyAdmin));
    }

    /**
     * @dev Test checks that it is allowed to get synthetic token implementation
     */
    function testGetHypERC20ImplementationAddress() public view {
        assertEq(proxyAdmin.getProxyImplementation(hypERC20Proxy), hypERC20ImplementationAddress);
    }

    /**
     * @dev Test checks that nobody is able to call .initializeV2() function after the proxy upgrade.
     */
    function testChecksEspressoERC20InitializeV2NotExecutable() public {
        EspHypERC20 espressoERC20Token = EspHypERC20(payable(hypERC20TokenAddress));

        vm.prank(proxyAdminOwner);
        vm.expectRevert(bytes("Initializable: contract is already initialized"));
        espressoERC20Token.initializeV2(address(1), 1, 1, treasury);
    }

    /**
     * @dev Test checks that not owner of proxy admin contract is NOT able to upgrade hyp synthetic proxy;
     */
    function testNotOwnerHypERC20Upgrade() public {
        vm.selectFork(destinationChain);
        HypERC20 hypERC20Token = HypERC20(payable(hypERC20TokenAddress));

        uint256 initialScale = hypERC20Token.scale();

        EspHypERC20 espressoERC20Implementation = new EspHypERC20(decimals, initialScale, destinationConfig.mailbox);

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

        EspHypERC20 espressoERC20Implementation = new EspHypERC20(decimals, initialScale, destinationConfig.mailbox);

        vm.prank(notProxyAdminOwner);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        proxyAdmin.upgradeAndCall(hypERC20Proxy, address(espressoERC20Implementation), "");
    }

    receive() external payable {}
}
