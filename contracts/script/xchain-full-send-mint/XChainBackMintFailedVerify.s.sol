// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

contract XChainBackMintFailedVerifyScript is Script, Test {
    function run() public view {
        uint256 amount = vm.envUint("XCHAIN_AMOUNT_WEI");
        uint256 recipientBalanceBefore = vm.envUint("RECIPIENT_BALANCE_BEFORE");
        address recipient = vm.envAddress("RECIPIENT");

        // Recipient should receive native tokens amount back after failed NFTs min on destination chain
        assertEq(recipient.balance, recipientBalanceBefore + amount);
    }
}
