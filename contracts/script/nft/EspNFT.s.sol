// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";
import "../../src/EspNFT.sol";
import "../../src/libs/Treasury.sol";

contract EspNFTScript is Script {
    string baseImageUri = vm.envString("BASE_IMAGE_URI");
    string chain = vm.envString("CHAIN_NAME");
    address espHypErc20 = vm.envAddress("HYPERLANE_TOKEN_ADDRESS");
    uint256 nftSalePriceWei = vm.envUint("DESTINATION_SALE_PRICE_WEI");
    address payable espressoTreasury = payable(vm.envAddress("ESPRESSO_TREASURY_ADDRESS"));
    address payable partnerTreasury = payable(vm.envAddress("PARTNER_TREASURY_ADDRESS"));
    uint256 espressoTreasuryPercentage = vm.envUint("ESPRESSO_TREASURY_PERCENTAGE");
    string name = "Espresso Composables NFT";
    string symbol = "EC";
    uint256 saleTimeStart = vm.envOr("SALE_TIME_START", block.timestamp + 10);

    function run() public {
        vm.startBroadcast();
        Treasury.TreasuryConfig memory treasury =
            Treasury.TreasuryConfig(espressoTreasury, partnerTreasury, espressoTreasuryPercentage);
        new EspNFT(name, symbol, baseImageUri, chain, espHypErc20, treasury, nftSalePriceWei, saleTimeStart);
        vm.stopBroadcast();
    }
}
