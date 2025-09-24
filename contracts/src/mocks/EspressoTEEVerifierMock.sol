pragma solidity 0.8.30;

import {IEspressoTEEVerifier} from "espresso-tee-contracts/src/interface/IEspressoTEEVerifier.sol";

contract EspressoTEEVerifierMock {
    function verify(bytes memory, bytes32, IEspressoTEEVerifier.TeeType) external pure returns (bool) {
        return true;
    }

    function registerSigner(bytes calldata attestation, bytes calldata data, IEspressoTEEVerifier.TeeType teeType)
        external
    {}

    function registeredSigners(address, IEspressoTEEVerifier.TeeType) external pure returns (bool) {
        return true;
    }
}
