// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title P²C Core Attestation Registry (Epoch 1)
/// @notice Implements the Automated ALP Policy Gate via ZK-SNARKs.

interface IGroth16Verifier {
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[3] calldata _pubSignals // [crmf_validity_seal, kani_proof_hash, max_drift]
    ) external view returns (bool);
}

contract AttestationRegistry {
    IGroth16Verifier public immutable verifier;

    // The WORM (Write-Once-Read-Many) Audit Trail for L0 Scope Bounds
    struct Attestation {
        uint256 timestamp;
        uint256 kaniProofHash;
        uint256 maxDrift;
        address submittingAgent;
    }

    // Mapping the CRMF Validity Seal to its recorded Attestation
    mapping(uint256 => Attestation) public registry;

    event LawfulStateTransitionLocked(uint256 indexed crmfValiditySeal, uint256 kaniProofHash);
    event L0_HALT_Triggered(address indexed agent, string reason);

    constructor(address _verifierAddress) {
        verifier = IGroth16Verifier(_verifierAddress);
    }

    /// @notice Submits a zero-knowledge proof of a lawful, contractive state transition.
    /// @dev If the ZK proof fails, the transaction reverts (L0_HALT).
    function registerAttestation(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint256 crmfValiditySeal,
        uint256 kaniProofHash,
        uint256 maxDrift
    ) external {
        // Prevent replay attacks (WORM policy)
        require(registry[crmfValiditySeal].timestamp == 0, "CRMF Seal already registered");

        // The public signals array expected by the snarkjs verifier
        uint[3] memory pubSignals = [crmfValiditySeal, kaniProofHash, maxDrift];

        // The Triple-Lock: Validates Kani bounds, Energy Conservation, and Poseidon2 Trace
        bool isValid = verifier.verifyProof(a, b, c, pubSignals);
        
        if (!isValid) {
            emit L0_HALT_Triggered(msg.sender, "SIG_GOV_KILL: ZK Proof Validation Failed");
            revert("Invalid State Transition");
        }

        // Lock the valid trace into the registry
        registry[crmfValiditySeal] = Attestation({
            timestamp: block.timestamp,
            kaniProofHash: kaniProofHash,
            maxDrift: maxDrift,
            submittingAgent: msg.sender
        });

        emit LawfulStateTransitionLocked(crmfValiditySeal, kaniProofHash);
    }
}
