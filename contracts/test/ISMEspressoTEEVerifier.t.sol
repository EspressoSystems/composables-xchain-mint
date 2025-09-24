pragma solidity 0.8.30;

import "forge-std/src/Test.sol";
import "../src/ism/ISMEspressoTEEVerifier.sol";
import "../src/mocks/EspressoTEEVerifierMock.sol";
import {CheckpointLib} from "@hyperlane-core/solidity/contracts/libs/CheckpointLib.sol";

contract ISMEspressoTEEVerifierTest is Test {
    ISMEspressoTEEVerifier public iSMEspressoTEEVerifier;
    EspressoTEEVerifierMock public teeVerifierMock;

    address public signer = makeAddr(string(abi.encode(1)));
    uint256 public privateKey = 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e;

    function setUp() public {
        teeVerifierMock = new EspressoTEEVerifierMock();
        iSMEspressoTEEVerifier = new ISMEspressoTEEVerifier(address(teeVerifierMock));
    }

    /**
     * @dev Test checks that valid EspressoTEEVerifier set during deployment
     */
    function testEspressoTEEVerifierSet() public view {
        address espressoTEEVerifier = address(iSMEspressoTEEVerifier.espressoTEEVerifier());
        assertEq(address(teeVerifierMock), espressoTEEVerifier);
    }

    /**
     * @dev Test checks that moduleType returns MESSAGE_ID_MULTISIG type
     * that reads contract that implements IInterchainSecurityModule interface
     */
    function testModuleTypeSucceed() public view {
        uint8 moduleType = iSMEspressoTEEVerifier.moduleType();
        // 5 is Module type MESSAGE_ID_MULTISIG in hyperlane contracts.
        assertEq(5, moduleType);
    }

    /**
     * @dev Test checks that registeredSigners returns true if registered
     */
    function testRegisteredSignersSucceed() public view {
        bool result = iSMEspressoTEEVerifier.registeredSigners(signer, IEspressoTEEVerifier.TeeType.NITRO);
        assertTrue(result);
    }

    /**
     * @dev Test makes proxy call on EspressoTEEVerifier to register signer and sets NITRO TEE type.
     */
    function testRegisterSignerSucceed() public {
        bytes memory attestation = hex"00112233445566778899aabbccddeeff";
        bytes memory signature = _sign(privateKey, bytes32(uint256(1)));
        iSMEspressoTEEVerifier.registerSigner(attestation, signature, IEspressoTEEVerifier.TeeType.NITRO);
    }

    /**
     * @dev Test makes verify() call on EspressoTEEVerifier and do the signature and userDataHash parsing.
     */
    function testVerifySucceed() public view {
        uint32 origin = 24;
        bytes32 merkleTreeHook = bytes32(uint256(uint160(address(2))));
        bytes32 checkpointRoot = keccak256(abi.encodePacked("checkpointRoot"));
        uint32 index = 24;

        bytes memory message = getHyperlaneMessage(origin);
        bytes32 messageId = keccak256(message);

        bytes32 userDataHash = CheckpointLib.digest(origin, merkleTreeHook, checkpointRoot, index, messageId);
        bytes memory signature = _sign(privateKey, userDataHash);
        bytes memory teeType = abi.encodePacked(IEspressoTEEVerifier.TeeType.NITRO);

        bytes memory metadata = getHyperlaneMetadata(merkleTreeHook, checkpointRoot, index, signature, teeType);

        bool result = iSMEspressoTEEVerifier.verify(metadata, message);
        assertTrue(result);
    }

    /**
     * @dev Test makes verify() call on EspressoTEEVerifier and fail due to not valid metadata.
     */
    function testVerifyRevertedInvalidMessage() public {
        uint32 origin = 24;
        bytes32 merkleTreeHook = bytes32(uint256(uint160(address(2))));
        bytes32 checkpointRoot = keccak256(abi.encodePacked("checkpointRoot"));
        uint32 index = 24;

        bytes memory message = getHyperlaneMessage(origin);
        bytes32 messageId = keccak256(message);
        bytes32 userDataHash = CheckpointLib.digest(origin, merkleTreeHook, checkpointRoot, index, messageId);
        bytes memory signature = _sign(privateKey, userDataHash);

        bytes memory shortMetadata = abi.encodePacked(signature, userDataHash);

        vm.prank(signer);

        vm.expectRevert(abi.encodeWithSelector(ISMEspressoTEEVerifier.ISMInvalidMetadata.selector, 134, 97));

        iSMEspressoTEEVerifier.verify(shortMetadata, message);
    }

    // Helpers

    function getHyperlaneMetadata(
        bytes32 merkleTreeHook,
        bytes32 checkpointRoot,
        uint32 index,
        bytes memory signature,
        bytes memory teeType
    ) public pure returns (bytes memory) {
        return abi.encodePacked(merkleTreeHook, checkpointRoot, index, signature, teeType);
    }

    function getHyperlaneMessage(uint32 origin) public pure returns (bytes memory) {
        bytes memory left = generateBytes(5);
        bytes memory right = generateBytes(68);
        return abi.encodePacked(left, origin, right);
    }

    function generateBytes(uint256 length) public pure returns (bytes memory result) {
        result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = bytes1(uint8(i % 256));
        }
    }

    function _sign(uint256 _privateKey, bytes32 userDataHash) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, userDataHash);
        return abi.encodePacked(r, s, v);
    }
}
