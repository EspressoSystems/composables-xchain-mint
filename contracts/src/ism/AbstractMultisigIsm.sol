pragma solidity 0.8.30;

import {IMultisigIsm} from "@hyperlane-core/solidity/contracts/interfaces/isms/IMultisigIsm.sol";
import {AbstractMultisig} from "@hyperlane-core/solidity/contracts/isms/multisig/AbstractMultisigIsm.sol";

/**
 * @title ForkedAbstractMultisigIsm without hyperlane verify function
 * @notice Manages per-domain m-of-n Validator sets of AbstractMultisig that are used to verify
 * interchain messages.
 */
abstract contract AbstractMultisigIsm is AbstractMultisig, IMultisigIsm {
    // ============ Virtual Functions ============
    // ======= OVERRIDE THESE TO IMPLEMENT =======

    /**
     * @notice Returns the set of validators responsible for verifying _message
     * and the number of signatures required
     * @dev Can change based on the content of _message
     * @dev Signatures provided to `verify` must be consistent with validator ordering
     * @param _message Hyperlane formatted interchain message
     * @return validators The array of validator addresses
     * @return threshold The number of validator signatures needed
     */
    function validatorsAndThreshold(bytes calldata _message) public view virtual returns (address[] memory, uint8);
}
