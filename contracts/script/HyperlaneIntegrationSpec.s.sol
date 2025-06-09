// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {HyperlaneIntegrationSpec} from "../src/HyperlaneIntegrationSpec.sol";

contract HyperlaneIntegrationSpecScript is Script {
    HyperlaneIntegrationSpec public spec;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        spec = new HyperlaneIntegrationSpec();

        vm.stopBroadcast();
    }
}
