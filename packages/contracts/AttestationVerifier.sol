// contracts/AttestationVerifier.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AttestationVerifier {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // Mapping from hardware spec hash to the current certificate root.
    mapping(bytes32 => bytes32) public attestedRoots;
    mapping(bytes32 => bool) public isAttested;

    // Address of the hardware vendor (will sign certificates).
    address public hardwareVendor;

    constructor(address _hardwareVendor) {
        hardwareVendor = _hardwareVendor;
    }

    /// @dev Submit a new certificate.
    function submitCertificate(
        bytes32 hardwareSpecHash,
        bytes32 merkleRoot,
        uint64 timestamp,
        uint64 nonce,
        bytes calldata signature
    ) external {
        // Recover the signer from the signature.
        bytes32 payloadHash = keccak256(abi.encodePacked(hardwareSpecHash, merkleRoot, timestamp, nonce));
        address signer = payloadHash.toEthSignedMessageHash().recover(signature);
        require(signer == hardwareVendor, "Invalid signer");

        // Record the attestation.
        attestedRoots[hardwareSpecHash] = merkleRoot;
        isAttested[hardwareSpecHash] = true;
    }

    /// @dev Verify that a specific term is included in the attested class set.
    function verifyTerm(
        bytes32 hardwareSpecHash,
        bytes32 termHash,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        bytes32 root = attestedRoots[hardwareSpecHash];
        require(root != bytes32(0), "Hardware spec not attested");
        return MerkleProof.verify(merkleProof, root, termHash);
    }
}
