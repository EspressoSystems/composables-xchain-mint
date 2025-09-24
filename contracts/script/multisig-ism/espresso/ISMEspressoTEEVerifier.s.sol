pragma solidity 0.8.30;

import "forge-std/src/Script.sol";

import "../../../src/ism/ISMEspressoTEEVerifier.sol";

contract ISMEspressoTEEVerifierScript is Script {
    function setUp() public {}

    function run() public {
        address baseTEEVerifier = vm.envAddress("ESPRESSO_TEE_VERIFIER_ADDRESS");
        vm.startBroadcast();
        new ISMEspressoTEEVerifier(baseTEEVerifier);
        vm.stopBroadcast();
    }
}
