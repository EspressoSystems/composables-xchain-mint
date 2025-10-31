// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/src/Script.sol";

import "../src/CREATE3Factory.sol";

contract DeployCREATE3FactoryScript is Script {
    function run() public {
        vm.broadcast();
        new CREATE3Factory();
    }
}
