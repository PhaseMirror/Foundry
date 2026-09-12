// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IRisc0Verifier
 * @notice Interface for RISC0 proof verification
 */
interface IRisc0Verifier {
    function verify(bytes calldata receipt, bytes32 imageId, bytes32 journalSha256) external view;
}

/**
 * @title ISp1Verifier
 * @notice Interface for SP1 proof verification
 */
interface ISp1Verifier {
    function verifyProof(bytes32 vkBytes, bytes calldata publicValues, bytes calldata proofBytes) external view;
}

/**
 * @title StarkVerifier
 * @notice Aggregate STARK verifier wrapping RISC0 and SP1 verifiers
 */
contract StarkVerifier {
    address public owner;
    IRisc0Verifier public risc0Verifier;
    ISp1Verifier public sp1Verifier;

    event OwnerTransferred(address indexed oldOwner, address indexed newOwner);
    event Risc0VerifierSet(address indexed verifier);
    event Sp1VerifierSet(address indexed verifier);
    event Verified(string verifierType, bytes32 indexed vkHash, bytes32 indexed proofHash, bool success);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "zero owner");
        owner = _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero owner");
        emit OwnerTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setRisc0Verifier(address verifier) external onlyOwner {
        require(verifier != address(0), "zero verifier");
        risc0Verifier = IRisc0Verifier(verifier);
        emit Risc0VerifierSet(verifier);
    }

    function setSp1Verifier(address verifier) external onlyOwner {
        require(verifier != address(0), "zero verifier");
        sp1Verifier = ISp1Verifier(verifier);
        emit Sp1VerifierSet(verifier);
    }

    /**
     * @notice Verify a RISC0 proof
     * @param vkHash Hash of the verification key (for event emission)
     * @param proofHash Hash of the proof (for event emission)
     * @param receipt RISC0 receipt bytes
     * @param imageId RISC0 program image ID
     * @param journalSha256 SHA256 hash of the journal
     */
    function verifyRisc0(
        bytes32 vkHash,
        bytes32 proofHash,
        bytes calldata receipt,
        bytes32 imageId,
        bytes32 journalSha256
    ) external {
        require(address(risc0Verifier) != address(0), "risc0 verifier not set");

        // Call the underlying verifier - it will revert on failure
        risc0Verifier.verify(receipt, imageId, journalSha256);

        emit Verified("risc0", vkHash, proofHash, true);
    }

    /**
     * @notice Verify an SP1 proof
     * @param vkHash Hash of the verification key (for event emission)
     * @param proofHash Hash of the proof (for event emission)
     * @param vkBytes Verification key bytes (as bytes32)
     * @param publicValues Public values for the proof
     * @param proofBytes The proof bytes
     */
    function verifySp1(
        bytes32 vkHash,
        bytes32 proofHash,
        bytes32 vkBytes,
        bytes calldata publicValues,
        bytes calldata proofBytes
    ) external {
        require(address(sp1Verifier) != address(0), "sp1 verifier not set");

        // Call the underlying verifier - it will revert on failure
        sp1Verifier.verifyProof(vkBytes, publicValues, proofBytes);

        emit Verified("sp1", vkHash, proofHash, true);
    }
}
