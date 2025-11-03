// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";
import "../../src/EspNFT.sol";
import "../../src/libs/Treasury.sol";

contract EspNFTScript is Script {
    string baseImageUri = vm.envString("BASE_IMAGE_URI");
    string chain = vm.envString("CHAIN_NAME");
    address espHypErc20 = vm.envAddress("HYPERLANE_TOKEN_ADDRESS");
    uint256 nftSalePrice = vm.envUint("NFT_SALE_PRICE_WEI");
    address payable mainTreasury = payable(vm.envAddress("MAIN_TREASURY_ADDRESS"));
    address payable secondaryTreasury = payable(vm.envAddress("SECONDARY_TREASURY_ADDRESS"));
    uint256 mainTreasuryPercentage = vm.envUint("MAIN_TREASURY_PERCENTAGE");
    string name = "Espresso Composables NFT";
    string symbol = "EC";
    uint256 currentTime = block.timestamp;

    function run() public {
        vm.startBroadcast();
        Treasury.TreasuryStruct memory treasury =
            Treasury.TreasuryStruct(mainTreasury, secondaryTreasury, mainTreasuryPercentage);
        new EspNFT(name, symbol, baseImageUri, chain, espHypErc20, treasury, nftSalePrice, currentTime);
        vm.stopBroadcast();
    }
}
