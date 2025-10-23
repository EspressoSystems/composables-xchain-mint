// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";
import "../../src/EspNFT.sol";

contract EspNFTScript is Script {
    string baseImageUri = vm.envString("BASE_IMAGE_URI");
    string chain = vm.envString("CHAIN_NAME");
    address espHypErc20 = vm.envAddress("HYPERLANE_TOKEN_ADDRESS");
    string name = 'Espresso Composables NFT';
    string symbol = 'EC';


    function run() public {
        vm.startBroadcast();
        new EspNFT(name, symbol, baseImageUri, chain, espHypErc20);
        vm.stopBroadcast();
    }
}
