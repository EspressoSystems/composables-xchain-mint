// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/src/Test.sol";
import {HyperlaneIntegrationSpec} from "../src/HyperlaneIntegrationSpec.sol";

contract HyperlaneIntegrationSpecTestBasic is Test {
    HyperlaneIntegrationSpec public spec;

    function setUp() public {
        spec = new HyperlaneIntegrationSpec();
    }
}

contract HyperlaneIntegrationSpecTestTwoChains is Test {
    HyperlaneIntegrationSpec public spec;

    function setUp() public {
        /**
         * This function should:
         *     1. Create two vms, each initialized from Anvil instances with Hyperlane contracts deployed.
         */
    }
}

contract HyperlaneIntegrationSpecTestFiveChains is Test {
    HyperlaneIntegrationSpec public spec;

    function setUp() public {
        /**
         * This function should:
         *     1. Create five vms, each initialized from Anvil instances with Hyperlane contracts deployed.
         */
    }
}
