// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {EspNFT} from "../../src/EspNFT.sol";
import {EspHypERC20} from "../../src/EspHypERC20.sol";
import {Treasury} from "../../src/libs/Treasury.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract FixApechain is Script {
    // ==================== NFT Config ====================
    string constant NAME = "Espresso Brews Rari";
    string constant SYMBOL = "BREW";
    string constant BASE_IMAGE_URI = "https://xchain-nft.s3.us-east-2.amazonaws.com/rari/";
    string constant CHAIN_NAME = "Rari";
    address constant ESP_HYP_ERC20 = 0x3e08Ad7C3fD70D08CdD2a11247dae18Eb06434FD;
    address constant PRICE_ADMIN = 0xD50a66B631544454b21BC32f5A2723428dbf3073;
    uint256 constant NFT_SALE_PRICE = 12000000000000000000; // 12 APE
    uint256 constant START_SALE = 1765202400; // Mon Dec 8 15:00 CET 2025
    uint256 constant END_SALE = 1767628800; // Mon Jan 5 17:00 CET 2026

    // ==================== Treasury Config ====================
    address payable constant ESPRESSO_TREASURY = payable(0xD3F14acB49456Bc41912e6580614Ad4b6D49a720);
    address payable constant PARTNER_TREASURY = payable(0x053F171c0D0Cc9d76247D4d1CdDb280bf1131390);
    uint256 constant ESPRESSO_PERCENTAGE = 7500; // 75%

    // ==================== Upgrade Config ====================
    address payable constant ESP_HYP_ERC20_PROXY = payable(0x3e08Ad7C3fD70D08CdD2a11247dae18Eb06434FD);
    address constant PROXY_ADMIN = 0xAb0Ea363Dd1e8492425DB15798632485A94Aa17e;
    address constant MAILBOX = 0x017be100600eCee055Eb27FA3b318E05Db79caD6;

    // ==================== RPC ====================
    string constant RPC_URL = "https://apechain.mainnet.on.espresso.network";

    function run() public {
        console.log("=== Fix Apechain: Deploy NFT + Upgrade EspHypERC20 ===");
        console.log("");

        Treasury.TreasuryConfig memory treasury = Treasury.TreasuryConfig({
            espresso: ESPRESSO_TREASURY,
            partner: PARTNER_TREASURY,
            percentageEspresso: ESPRESSO_PERCENTAGE
        });

        vm.startBroadcast();

        // 1. Deploy new NFT
        console.log("1. Deploying new EspNFT...");
        EspNFT nft = new EspNFT(
            NAME,
            SYMBOL,
            BASE_IMAGE_URI,
            CHAIN_NAME,
            ESP_HYP_ERC20,
            PRICE_ADMIN,
            treasury,
            NFT_SALE_PRICE,
            START_SALE,
            END_SALE
        );
        console.log("   EspNFT deployed at:", address(nft));

        // 2. Deploy new EspHypERC20 implementation
        console.log("2. Deploying new EspHypERC20 implementation...");
        EspHypERC20 newImpl = new EspHypERC20(18, 1, MAILBOX);
        console.log("   Implementation deployed at:", address(newImpl));

        // 3. Upgrade proxy
        console.log("3. Upgrading proxy...");
        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN);
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(ESP_HYP_ERC20_PROXY);
        proxyAdmin.upgrade(proxy, address(newImpl));
        console.log("   Proxy upgraded");

        // 4. Set new NFT address
        console.log("4. Setting rariMarketplace...");
        EspHypERC20(ESP_HYP_ERC20_PROXY).setRariMarketplace(address(nft));
        console.log("   rariMarketplace set to:", address(nft));

        vm.stopBroadcast();

        // 5. Verify
        console.log("5. Verifying...");

        require(nft.espHypErc20() == ESP_HYP_ERC20, "NFT.espHypErc20 mismatch");
        console.log("   NFT.espHypErc20:", nft.espHypErc20());

        require(
            EspHypERC20(ESP_HYP_ERC20_PROXY).rariMarketplace() == address(nft), "EspHypERC20.rariMarketplace mismatch"
        );
        console.log("   EspHypERC20.rariMarketplace:", EspHypERC20(ESP_HYP_ERC20_PROXY).rariMarketplace());

        require(proxyAdmin.getProxyImplementation(proxy) == address(newImpl), "Proxy implementation mismatch");
        console.log("   Proxy implementation:", proxyAdmin.getProxyImplementation(proxy));

        console.log("");
        console.log("=== All verifications passed ===");
    }
}
