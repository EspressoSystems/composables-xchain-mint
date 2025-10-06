// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {EspHypERC20} from "../../src/EspHypERC20.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract UpgradeERC20TokenScript is Script, Test {
    function run() public {
        address mailboxAddress = vm.envAddress("MAILBOX_ADDRESS");
        address payable hypERC20Token = payable(vm.envAddress("HYPERLANE_TOKEN_ADDRESS"));
        ProxyAdmin proxyAdmin = ProxyAdmin(vm.envAddress("PROXY_ADMIN_ADDRESS"));
        address marketplaceAddress = vm.envAddress("MARKETPLACE_ADDRESS");
        address treasuryAddress = vm.envAddress("TREASURY_ADDRESS");
        uint32 destinationDomainId = uint32(vm.envUint("DESTINATION_DOMAIN_ID"));

        uint8 decimals = 18;
        uint256 scale = 1;

        ITransparentUpgradeableProxy hypERC20Proxy = ITransparentUpgradeableProxy(hypERC20Token);

        bytes memory initializeV2Data = abi.encodeWithSelector(
            EspHypERC20.initializeV2.selector, marketplaceAddress, treasuryAddress, destinationDomainId
        );
        vm.startBroadcast();
        EspHypERC20 espressoERC20TokenImplementation = new EspHypERC20(decimals, scale, mailboxAddress);

        proxyAdmin.upgradeAndCall(hypERC20Proxy, address(espressoERC20TokenImplementation), initializeV2Data);
        assertEq(proxyAdmin.getProxyImplementation(hypERC20Proxy), address(espressoERC20TokenImplementation));

        vm.stopBroadcast();
    }
}
