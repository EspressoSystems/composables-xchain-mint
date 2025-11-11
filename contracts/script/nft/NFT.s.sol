// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";
import "../../src/mocks/MockERC721.sol";

contract NFTScript is Script {
    function run() public {
        vm.startBroadcast();
        new MockERC721();
        vm.stopBroadcast();
    }
}
