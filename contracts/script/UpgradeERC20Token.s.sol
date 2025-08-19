// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {EspressoERC20} from "../src/EspressoERC20.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract UpgradeERC20TokenScript is Script, Test {

    function run() public {
        uint8 decimals = 18;
        uint256 scale = 1;
        address mailboxAddress = vm.envAddress("MAILBOX_ADDRESS");

        address payable hypERC20Token = payable(vm.envAddress("HYPERLANE_TOKEN_ADDRESS"));
        ITransparentUpgradeableProxy hypERC20Proxy = ITransparentUpgradeableProxy(hypERC20Token);

        ProxyAdmin proxyAdmin = ProxyAdmin(vm.envAddress("PROXY_ADMIN_ADDRESS"));

        vm.startBroadcast();
        EspressoERC20 espressoERC20TokenImplementation = new EspressoERC20(decimals, scale, mailboxAddress);

        proxyAdmin.upgrade(hypERC20Proxy, address(espressoERC20TokenImplementation));
        assertEq(proxyAdmin.getProxyImplementation(hypERC20Proxy), address(espressoERC20TokenImplementation));

        vm.stopBroadcast();
    }
}
