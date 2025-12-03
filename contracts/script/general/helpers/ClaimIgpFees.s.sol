// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script, console} from "forge-std/src/Script.sol";
import {InterchainGasPaymaster} from "@hyperlane-core/solidity/contracts/hooks/igp/InterchainGasPaymaster.sol";

contract ClaimIgpFeesScript is Script {
    address interchainGasPaymasterAddress = 0x122bF1B008dAbc71d9732263ceF16e0e6562FE3a;

    function run() public {
        vm.startBroadcast();
        InterchainGasPaymaster interchainGasPaymaster = InterchainGasPaymaster(interchainGasPaymasterAddress);
        address beneficiary = interchainGasPaymaster.beneficiary();

        console.log("beneficiary: ");
        console.log(beneficiary);
        if (address(interchainGasPaymaster).balance > 0) {
            interchainGasPaymaster.claim();
        } else {
            console.log("Nothing to collect from interchainGasPaymaster");
        }

        vm.stopBroadcast();
    }
}
