// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {HyperlaneAddressesConfig} from "../../script/configs/HyperlaneAddressesConfig.sol";
import "../../src/mocks/MockERC721.sol";

contract NFTScript is Script, Test, HyperlaneAddressesConfig {
    function run() public {
        vm.startBroadcast();
        new MockERC721();
        vm.stopBroadcast();
    }
}
