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
        uint256 saleTimeStart = vm.envUint("SALE_TIME_START");
        address mailboxAddress = vm.envAddress("MAILBOX_ADDRESS");

        address payable hypNativeToken = payable(vm.envAddress("HYPERLANE_TOKEN_ADDRESS"));
        ITransparentUpgradeableProxy hypNativeProxy = ITransparentUpgradeableProxy(hypNativeToken);
        uint256 nftSalePriceWei = vm.envUint("SOURCE_SALE_PRICE_WEI");
        uint32 destinationDomainId = uint32(vm.envUint("DESTINATION_DOMAIN_ID"));

        ProxyAdmin proxyAdmin = ProxyAdmin(vm.envAddress("PROXY_ADMIN_ADDRESS"));

        vm.startBroadcast();
        EspHypNative espressoNativeTokenImplementation =
            new EspHypNative(scale, mailboxAddress, saleTimeStart, nftSalePriceWei);

        proxyAdmin.upgrade(hypNativeProxy, address(espressoNativeTokenImplementation));

        EspHypNative espressoNativeToken = EspHypNative(hypNativeToken);
        espressoNativeToken.initializeV2(nftSalePriceWei, destinationDomainId, saleTimeStart);

        assertEq(proxyAdmin.getProxyImplementation(hypNativeProxy), address(espressoNativeTokenImplementation));

        vm.stopBroadcast();
    }
}
