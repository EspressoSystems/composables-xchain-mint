pragma solidity 0.8.30;

import {PackageVersioned} from "@hyperlane-core/solidity/contracts/PackageVersioned.sol";
import {IMultisigIsm} from "@hyperlane-core/solidity/contracts/interfaces/isms/IMultisigIsm.sol";

/**
 * @title Forked AbstractMultisig
 * @notice Manages per-domain m-of-n Validator sets
 * @dev See AbstractMerkleRootMultisigIsm.sol and AbstractMessageIdMultisigIsm.sol
 * for concrete implementations of `digest` and `signatureAt`.
 * @dev See StaticMultisigIsm.sol for concrete implementations.
 */
abstract contract AbstractMultisig is PackageVersioned {
    /**
     * @notice Returns the digest to be used for signature verification.
     * @param _metadata ABI encoded module metadata
     * @param _message Formatted Hyperlane message (see Message.sol).
     * @return digest The digest to be signed by validators
     */
    function digest(bytes calldata _metadata, bytes calldata _message) internal view virtual returns (bytes32);

    /**
     * @notice Returns the signature at a given index from the metadata.
     * @param _metadata ABI encoded module metadata
     * @param _index The index of the signature to return
     * @return signature Packed encoding of signature (65 bytes)
     */
    function signatureAt(bytes calldata _metadata, uint256 _index) internal pure virtual returns (bytes calldata);

    /**
     * @notice Returns the number of signatures in the metadata.
     * @param _metadata ABI encoded module metadata
     * @return count The number of signatures
     */
    function signatureCount(bytes calldata _metadata) public pure virtual returns (uint256);
}

/**
 * @title ForkedAbstractMultisigIsm
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
