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
    address payable priceAdmin = payable(vm.envAddress("PRICE_ADMIN_ADDRESS"));
    uint256 espressoTreasuryPercentage = vm.envUint("ESPRESSO_TREASURY_PERCENTAGE");
    uint256 saleTimeStart = vm.envUint("SALE_TIME_START");
    string public name = "Bridgeless Minting NFT";
    string public symbol = "BM";

    function run() public {
        vm.startBroadcast();
        Treasury.TreasuryConfig memory treasury =
            Treasury.TreasuryConfig(espressoTreasury, partnerTreasury, espressoTreasuryPercentage);
        new EspNFT(name, symbol, baseImageUri, chain, espHypErc20, priceAdmin, treasury, nftSalePriceWei, saleTimeStart);
        vm.stopBroadcast();
    }
}
