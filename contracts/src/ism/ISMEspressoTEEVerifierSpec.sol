pragma solidity 0.8.30;

import {IEspressoTEEVerifier} from "espresso-tee-contracts/src/interface/IEspressoTEEVerifier.sol";
import "./AbstractMultisigIsm.sol";

/**
 * @title ISMEspressoTEEVerifier
 * @author Espresso Systems
 *
 * @dev This contract MUST be deployed using EspressoTEEVerifier contract set in the constructor.
 *
 * This contract MUST:
 * 1. Implement IInterchainSecurityModule.sol, IMultisigIsm.sol interfaces, abstract AbstractMultisigIsm contract.
 * 2. Implement proxy functions to call EspressoTEEVerifier contract registeredSigners(), registerSigner() that proxy calls with required parameters
 * 3. Implement IInterchainSecurityModule.verify() function, parse there data from the Mailbox contract, call EspressoTEEVerifier.verify() and validate response is verification successful.
 * 4. For more information about IInterchainSecurityModule.sol see Hyperlane docs: https://docs.hyperlane.xyz/docs/reference/ISM/specify-your-ISM
 */
contract ISMEspressoTEEVerifier is AbstractMultisigIsm {
    /**
     * @param baseTEEVerifier The address of the EspressoTEEVerifier
     */
    constructor(address baseTEEVerifier) {}

    /**
     * Function should be implemented according to the AbstractMultisig.
     */
    function digest(bytes calldata _metadata, bytes calldata _message) internal pure override returns (bytes32) {
        /**
         * return CheckpointLib.digest(
         *    _message.origin(), _metadata.originMerkleTreeHook(), _metadata.root(), _metadata.index(), _message.id()
         * );
         */
    }

    /**
     * Function should be implemented according to the AbstractMultisig.
     */
    function signatureAt(bytes calldata _metadata, uint256) internal pure virtual override returns (bytes calldata) {
        /**
         * Suggested implementation:
         *
         * return _metadata.signatureAt(_index);
         */
        return _metadata;
    }

    /**
     * Function should be implemented according to the AbstractMultisig.
     */
    function signatureCount(bytes calldata _metadata) public pure override returns (uint256) {
        /**
         * Suggested implementation:
         *
         * return _metadata.signatureCount();
         */
    }

    /**
     * Function should be implemented according to the AbstractMultisigIsm.
     */
    function validatorsAndThreshold(bytes calldata) public pure override returns (address[] memory, uint8) {
        /**
         * Suggested implementation:
         *
         * return abi.decode(MetaProxy.metadata(), (address[], uint8));
         */
    }

    /**
     * Function should be implemented according to the IInterchainSecurityModule.
     * It should return Type enum used with relayer carrying no metadata.
     */
    function moduleType() external pure returns (uint8) {
        /**
         * Suggested implementation:
         *
         * return uint8(Types.MESSAGE_ID_MULTISIG);
         */
    }

    /**
     * Function should do proxy call to EspressoTEEVerifier.registeredSigners().
     * It should return is Signer registered or not on EspressoTEEVerifier contract.
     */
    function registeredSigners(address signer, IEspressoTEEVerifier.TeeType teeType) external view returns (bool) {
        /**
         * Suggested implementation:
         *
         * return espressoTEEVerifier.registeredSigners(signer, teeType);
         */
    }

    /**
     * Function should do proxy call to EspressoTEEVerifier.registerSigner().
     */
    function registerSigner(bytes calldata attestation, bytes calldata data, IEspressoTEEVerifier.TeeType teeType)
        external
    {
        /**
         * Suggested implementation:
         *
         * espressoTEEVerifier.registerSigner(attestation, data, teeType);
         */
    }

    /**
     * @notice Requires that 1-of-1 validator verify a merkle root,
     * and verifies a merkle proof of `_message` against that root.
     * Function MUST implement IInterchainSecurityModule.verify() function.
     * It should return true if verification is successful or revert on external EspressoTEEVerifier if verification failed.
     * @param _metadata Off-chain metadata provided by a relayer, specific to
     * the security model encoded by the module (e.g. validator signatures).
     * Used to get validator signature, get userDataHash (in the way like hyperlane does that), get espresso tee type.
     * It should be at 134 bytes length. See MessageIdMultisigIsmMetadata.sol to see metadata format.
     * @param _message Hyperlane encoded interchain message (see Message.sol).
     */
    // solhint-disable-next-line no-unused-vars
    function verify(bytes calldata _metadata, bytes calldata _message) external pure returns (bool) {
        return true;
    }
}
