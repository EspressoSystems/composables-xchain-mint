// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {EspHypERC20} from "../../src/EspHypERC20.sol";
import "../../src/libs/Treasury.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract UpgradeERC20TokenScript is Script, Test {
    function run() public {
        address mailboxAddress = vm.envAddress("MAILBOX_ADDRESS");
        address payable hypERC20Token = payable(vm.envAddress("HYPERLANE_TOKEN_ADDRESS"));
        ProxyAdmin proxyAdmin = ProxyAdmin(vm.envAddress("PROXY_ADMIN_ADDRESS"));
        address marketplaceAddress = vm.envAddress("NFT_ADDRESS");
        address payable mainTreasury = payable(vm.envAddress("MAIN_TREASURY_ADDRESS"));
        address payable secondaryTreasury = payable(vm.envAddress("SECONDARY_TREASURY_ADDRESS"));
        uint256 mainTreasuryPercentage = vm.envUint("MAIN_TREASURY_PERCENTAGE");
        uint32 destinationDomainId = uint32(vm.envUint("DESTINATION_DOMAIN_ID"));
        uint256 bridgeBackPaymentAmount = vm.envUint("BRIDGE_BACK_PAYMENT_AMOUNT_WEI");

        uint8 decimals = 18;
        uint256 scale = 1;
        uint256 gasFeesDeposit = 0.1 ether;

        ITransparentUpgradeableProxy hypERC20Proxy = ITransparentUpgradeableProxy(hypERC20Token);
        Treasury.TreasuryStruct memory treasury =
            Treasury.TreasuryStruct(mainTreasury, secondaryTreasury, mainTreasuryPercentage);

        bytes memory initializeV2Data = abi.encodeWithSelector(
            EspHypERC20.initializeV2.selector,
            marketplaceAddress,
            destinationDomainId,
            bridgeBackPaymentAmount,
            treasury
        );
        vm.startBroadcast();
        EspHypERC20 espressoERC20TokenImplementation = new EspHypERC20(decimals, scale, mailboxAddress);

        proxyAdmin.upgradeAndCall(hypERC20Proxy, address(espressoERC20TokenImplementation), initializeV2Data);
        assertEq(proxyAdmin.getProxyImplementation(hypERC20Proxy), address(espressoERC20TokenImplementation));

        // Top up hypERC20Token with gasFeesDeposit to cover bridging tokens in case of NFT failed.
        (bool success,) = hypERC20Token.call{value: gasFeesDeposit}("");
        require(success, "ETH EspHypERC20  transfer failed");

        vm.stopBroadcast();
    }
}
