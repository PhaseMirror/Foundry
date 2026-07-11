// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IGroth16Verifier} from "./interfaces/IGroth16Verifier.sol";
 

interface IConsentRegistryView {
    function revoked(bytes32) external view returns (bool);
}

interface IHalo2Verifier {
    function verifyProof(bytes calldata proof, uint256[] calldata publicInputs) external view returns (bool);
}

struct BatchRunData {
    bytes32 digest;
    uint64 timestamp;
    bytes32 consentCommitment;
    bytes32 nullifier;
}

/// @title AttestationRegistry
/// @notice Verifies an attestation proof and links it with a valid consent proof; checks provider signature; emits audit event.
contract AttestationRegistry {
    using ECDSA for bytes32;

    IGroth16Verifier public consentVerifier;     // consent.circom
    IGroth16Verifier public attestationVerifier; // attestation.circom
    IHalo2Verifier public batchVerifier;         // recursive batch verifier
    IConsentRegistryView public consentRegistry; // optional revocation check

    // Allowlisted provider signers
    mapping(address => bool) public providerAllowed;
    mapping(address => bool) public authorizedSidecars;

    // Prevent replays per attestation+patient secret
    mapping(bytes32 => bool) public usedNullifier;

    // --- ALP Governance Invariants ---
    // Scaled by 10^3 (6.0 -> 6000) to match circuit fixed-point arithmetic
    uint256 public constant MAX_ALLOWED_ENTROPY = 6000; 
    uint256 public constant MAX_ALLOWED_UNSTABLE = 0;

    // Emergency Circuit Breaker Flag (triggered by SIG_GOV_KILL sidecar)
    bool public isL0Halted = false;

    event VerifiersSet(address consentV, address attestV, address batchV);
    event ConsentRegistrySet(address reg);
    event ProviderAllowed(address provider, bool allowed);
    event SidecarAuthorized(address sidecar, bool allowed);

    event Attested(
        bytes32 indexed attestationDigest,
        uint64 timestampEpoch,
        address indexed provider,
        bytes32 indexed consentCommitment,
        bytes32 nullifier
    );

    event BatchAttested(
        bytes32 indexed batchMerkleRoot,
        uint256 runCount,
        address indexed sidecar
    );

    event GovernanceHalt(address indexed triggeredBy, bytes32 reasonHash);

    // Modifier to strictly enforce the fail-closed operational state
    modifier onlySafeMode() {
        if (isL0Halted) revert("L0_HALT: Protocol suspended by Phase Mirror");
        _;
    }

    error InvalidProof();
    error Mismatch();
    error Revoked();
    error NotProvider();
    error Replay();

    constructor(address consentV, address attestV, address batchV, address consentReg) {
        consentVerifier = IGroth16Verifier(consentV);
        attestationVerifier = IGroth16Verifier(attestV);
        batchVerifier = IHalo2Verifier(batchV);
        consentRegistry = IConsentRegistryView(consentReg);
        emit VerifiersSet(consentV, attestV, batchV);
        emit ConsentRegistrySet(consentReg);
    }

    function setVerifiers(address consentV, address attestV, address batchV) external {
        consentVerifier = IGroth16Verifier(consentV);
        attestationVerifier = IGroth16Verifier(attestV);
        batchVerifier = IHalo2Verifier(batchV);
        emit VerifiersSet(consentV, attestV, batchV);
    }

    function setConsentRegistry(address reg) external {
        consentRegistry = IConsentRegistryView(reg);
        emit ConsentRegistrySet(reg);
    }

    function setProvider(address signer, bool allowed) external {
        providerAllowed[signer] = allowed;
        emit ProviderAllowed(signer, allowed);
    }

    function setSidecar(address sidecar, bool allowed) external {
        authorizedSidecars[sidecar] = allowed;
        emit SidecarAuthorized(sidecar, allowed);
    }

    /// @param consentPub  10 public signals from consent proof (see ConsentRegistry)
    /// @param attestPub    5 public signals from attestation proof: [digest, provider_pk, timestamp, consent_commitment, nullifier]
    /// @param signature    ECDSA over keccak256(abi.encodePacked(digest, uint64(timestamp)))
    function submitAttestation(
        uint256[2] calldata cA,
        uint256[2][2] calldata cB,
        uint256[2] calldata cC,
        uint256[10] calldata consentPub,
        uint256[2] calldata aA,
        uint256[2][2] calldata aB,
        uint256[2] calldata aC,
        uint256[5] calldata attestPub,
        bytes calldata signature
    ) external {
        // fixed-size public inputs: consentPub(10) and attestPub(5)

        // 1) Verify both proofs
        if (!consentVerifier.verifyProof(cA, cB, cC, consentPub)) revert InvalidProof();
        if (!attestationVerifier.verifyProof(aA, aB, aC, attestPub)) revert InvalidProof();

        // consent: [0]=purpose [1]=scope [2]=provider_pk [7]=consent_commitment [9]=nullifier
        // attest : [0]=digest  [1]=provider_pk [2]=timestamp [3]=consent_commitment [4]=att_nullifier
        if (consentPub[2] != attestPub[1]) revert Mismatch();
        if (consentPub[7] != attestPub[3]) revert Mismatch();

        // 2) Check provider signature and allowlist
        bytes32 digest = bytes32(attestPub[0]);
        uint64 timestamp = uint64(attestPub[2]);
        bytes32 msgHash = keccak256(abi.encodePacked(digest, timestamp));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(msgHash);
        address signer = ECDSA.recover(ethSignedHash, signature);
        if (!providerAllowed[signer]) revert NotProvider();

        // provider_pk in circuit must equal signer address as uint160
        if (uint256(uint160(signer)) != attestPub[1]) revert Mismatch();

        // 3) Revocation and replay checks
        if (address(consentRegistry) != address(0)) {
            if (consentRegistry.revoked(bytes32(consentPub[9]))) revert Revoked();
        }
        bytes32 nullifier = bytes32(attestPub[4]);
        if (usedNullifier[nullifier]) revert Replay();
        usedNullifier[nullifier] = true;

        emit Attested(digest, timestamp, signer, bytes32(attestPub[3]), nullifier);
    }

    function _computeMerkleRoot(BatchRunData[] calldata runs) internal pure returns (bytes32) {
        // Simplified Merkle root for data availability.
        // In production, this matches the exact Poseidon/Keccak tree used in the Halo2 circuit.
        bytes32 currentHash = bytes32(0);
        for (uint256 i = 0; i < runs.length; i++) {
            currentHash = keccak256(abi.encodePacked(currentHash, runs[i].digest, runs[i].timestamp, runs[i].consentCommitment, runs[i].nullifier));
        }
        return currentHash;
    }

    /// @notice Submits a recursive Halo2 proof validating multiple Groth16 attestations and ALP bounds.
    function submitBatchAttestation(
        bytes calldata batchProof,
        bytes32 batchMerkleRoot,
        BatchRunData[] calldata runs,
        bytes calldata sidecarSignature
    ) external onlySafeMode {
        bytes32 msgHash = keccak256(abi.encodePacked(batchMerkleRoot, runs.length));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(msgHash);
        address sidecar = ECDSA.recover(ethSignedHash, sidecarSignature);
        if (!authorizedSidecars[sidecar]) revert NotProvider();

        uint256[] memory pubInputs = new uint256[](3);
        pubInputs[0] = uint256(batchMerkleRoot);
        pubInputs[1] = MAX_ALLOWED_ENTROPY;
        pubInputs[2] = MAX_ALLOWED_UNSTABLE;

        if (address(batchVerifier) != address(0)) {
            if (!batchVerifier.verifyProof(batchProof, pubInputs)) revert InvalidProof();
        }

        bytes32 computedRoot = _computeMerkleRoot(runs);
        if (computedRoot != batchMerkleRoot) revert Mismatch();

        for (uint256 i = 0; i < runs.length; i++) {
            if (address(consentRegistry) != address(0)) {
                // Ensure nullifier logic reflects Pirtm V2 calculus (consentCommitment bindings)
                if (consentRegistry.revoked(runs[i].consentCommitment)) revert Revoked();
            }
            if (usedNullifier[runs[i].nullifier]) revert Replay();
            usedNullifier[runs[i].nullifier] = true;
            
            emit Attested(runs[i].digest, runs[i].timestamp, sidecar, runs[i].consentCommitment, runs[i].nullifier);
        }
        
        emit BatchAttested(batchMerkleRoot, runs.length, sidecar);
    }

    /// @notice Allows an authorized sidecar to trip the circuit breaker during a SIG_GOV_KILL event.
    function triggerL0Halt(bytes32 reasonHash) external {
        if (!authorizedSidecars[msg.sender]) revert NotProvider();
        isL0Halted = true;
        emit GovernanceHalt(msg.sender, reasonHash);
    }
}
