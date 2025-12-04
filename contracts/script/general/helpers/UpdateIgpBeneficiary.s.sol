// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {EspHypERC20} from "../../../src/EspHypERC20.sol";
import {TypeCasts} from "@hyperlane-core/solidity/contracts/libs/TypeCasts.sol";
import {InterchainGasPaymaster} from "@hyperlane-core/solidity/contracts/hooks/igp/InterchainGasPaymaster.sol";

contract UpdateIgpBeneficiaryScript is Script {
    address beneficiaryAddress = vm.envAddress("BENEFICIARY_ADDRESS");
    address interchainGasPaymasterAddress = vm.envAddress("IGP_ADDRESS");

    function run() public {
        vm.startBroadcast();
        InterchainGasPaymaster interchainGasPaymaster = InterchainGasPaymaster(interchainGasPaymasterAddress);
        interchainGasPaymaster.setBeneficiary(beneficiaryAddress);
        vm.stopBroadcast();
    }
}
