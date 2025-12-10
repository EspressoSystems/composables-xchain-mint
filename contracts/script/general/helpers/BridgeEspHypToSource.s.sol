// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {EspHypERC20} from "../../../src/EspHypERC20.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";

contract BridgeEspHypToSourceScript is Script {
    using TypeCasts for address;
    // address payable espHypERC20Address = payable(0x29b0a57Cb774f513653a90d3a185eb12D4AAc3ad); // EspHypERC20 on Rarichain
    // uint256 payGasFees = 0.0005 ether; // ETH

    address payable espHypERC20Address = payable(0x3e08Ad7C3fD70D08CdD2a11247dae18Eb06434FD); // EspHypERC20 on Apechain
    uint256 payGasFees = 0.2 ether; // APE

    function run() public {
        vm.startBroadcast();
        EspHypERC20 espHypERC20 = EspHypERC20(espHypERC20Address);
        uint256 balance = espHypERC20.balanceOf(msg.sender);

        if (balance > 0) {
            uint32 domainId = espHypERC20.destinationDomainId();
            espHypERC20.transferRemote{value: payGasFees}(domainId, msg.sender.addressToBytes32(), balance);
        } else {
            console.log("Nothing to bridge back");
        }

        vm.stopBroadcast();
    }
}
