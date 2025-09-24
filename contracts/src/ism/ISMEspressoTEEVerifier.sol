pragma solidity 0.8.30;

import {Message} from "@hyperlane-core/solidity/contracts/libs/Message.sol";
import {MetaProxy} from "@hyperlane-core/solidity/contracts/libs/MetaProxy.sol";
import {CheckpointLib} from "@hyperlane-core/solidity/contracts/libs/CheckpointLib.sol";

import {IEspressoTEEVerifier} from "espresso-tee-contracts/src/interface/IEspressoTEEVerifier.sol";

import "../libs/MessageIdMultisigIsmMetadata.sol";
import "./AbstractMultisigIsm.sol";

contract ISMEspressoTEEVerifier is AbstractMultisigIsm {
    IEspressoTEEVerifier public immutable espressoTEEVerifier;

    error ISMInvalidMetadata(uint256 lengthRequired, uint256 lengthReceived);

    constructor(address baseTEEVerifier) {
        espressoTEEVerifier = IEspressoTEEVerifier(baseTEEVerifier);
    }

    /**
     * Function should implement accodrding to the IInterchainSecurityModule.
     * It should return Type enum MESSAGE_ID_MULTISIG used by relayer carrying metadata (for instance signatures and tee type).
     */
    function moduleType() external pure returns (uint8) {
        return uint8(Types.MESSAGE_ID_MULTISIG);
    }

    using Message for bytes;
    using MessageIdMultisigIsmMetadata for bytes;

    // ============ Constants ============

    /**
     * @inheritdoc AbstractMultisig
     */
    function digest(bytes calldata _metadata, bytes calldata _message) internal pure override returns (bytes32) {
        return CheckpointLib.digest(
            _message.origin(), _metadata.originMerkleTreeHook(), _metadata.root(), _metadata.index(), _message.id()
        );
    }

    function signatureAt(bytes calldata _metadata, uint256 _index)
        internal
        pure
        virtual
        override
        returns (bytes calldata)
    {
        return _metadata.signatureAt(_index);
    }

    function signatureCount(bytes calldata _metadata) public pure override returns (uint256) {
        return _metadata.signatureCount();
    }

    function espressoTeeType(bytes calldata _metadata) public pure returns (IEspressoTEEVerifier.TeeType) {
        return IEspressoTEEVerifier.TeeType(uint8(_metadata.espressoTeeType()));
    }

    function validatorsAndThreshold(bytes calldata) public pure override returns (address[] memory, uint8) {
        return abi.decode(MetaProxy.metadata(), (address[], uint8));
    }

    function registeredSigners(address signer, IEspressoTEEVerifier.TeeType teeType) external view returns (bool) {
        return espressoTEEVerifier.registeredSigners(signer, teeType);
    }

    function registerSigner(bytes calldata attestation, bytes calldata data, IEspressoTEEVerifier.TeeType teeType)
        external
    {
        espressoTEEVerifier.registerSigner(attestation, data, teeType);
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
    function verify(bytes calldata _metadata, bytes calldata _message) external view returns (bool) {
        if (_metadata.length != 134) revert ISMInvalidMetadata(134, _metadata.length);

        bytes memory signature = signatureAt(_metadata, 0);
        bytes32 userDataHash = digest(_metadata, _message);
        IEspressoTEEVerifier.TeeType teeType = IEspressoTEEVerifier.TeeType(uint8(_metadata.espressoTeeType()));

        return espressoTEEVerifier.verify(signature, userDataHash, teeType);
    }
}
