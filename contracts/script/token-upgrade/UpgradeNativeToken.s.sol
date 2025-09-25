// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {EspHypNative} from "../../src/EspHypNative.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract UpgradeNativeTokenScript is Script, Test {
    function run() public {
        uint256 scale = 1;
        address mailboxAddress = vm.envAddress("MAILBOX_ADDRESS");

        address payable hypNativeToken = payable(vm.envAddress("HYPERLANE_TOKEN_ADDRESS"));
        ITransparentUpgradeableProxy hypNativeProxy = ITransparentUpgradeableProxy(hypNativeToken);

        ProxyAdmin proxyAdmin = ProxyAdmin(vm.envAddress("PROXY_ADMIN_ADDRESS"));

        vm.startBroadcast();
        EspHypNative espressoNativeTokenImplementation = new EspHypNative(scale, mailboxAddress);

        proxyAdmin.upgrade(hypNativeProxy, address(espressoNativeTokenImplementation));
        assertEq(proxyAdmin.getProxyImplementation(hypNativeProxy), address(espressoNativeTokenImplementation));

        vm.stopBroadcast();
    }
}
