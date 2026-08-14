// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IGroth16Verifier} from "./interfaces/IGroth16Verifier.sol";
import {IDilithiumVerifier} from "./IDilithiumVerifier.sol";

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

    IGroth16Verifier public consentVerifier;
    IGroth16Verifier public attestationVerifier;
    IHalo2Verifier public batchVerifier;
    IConsentRegistryView public consentRegistry;

    mapping(address => bool) public providerAllowed;
    mapping(address => bool) public authorizedSidecars;

    // ADR-PML-051: Dilithium public keys for providers and sidecars.
    mapping(address => bytes) public dilithiumPublicKeys;
    IDilithiumVerifier public dilithiumVerifier;

    mapping(bytes32 => bool) public usedNullifier;

    uint256 public constant MAX_ALLOWED_ENTROPY = 6000;
    uint256 public constant MAX_ALLOWED_UNSTABLE = 0;
    bool public isL0Halted = false;

    event VerifiersSet(address consentV, address attestV, address batchV);
    event ConsentRegistrySet(address reg);
    event ProviderAllowed(address provider, bool allowed);
    event SidecarAuthorized(address sidecar, bool allowed);
    event DilithiumVerifierSet(address verifier);
    event DilithiumKeyRegistered(address indexed owner, bytes publicKey);

    event Attested(
        bytes32 indexed attestationDigest,
        uint64 timestampEpoch,
        address indexed provider,
        bytes32 indexed consentCommitment,
        bytes32 nullifier
    );

    event AttestedPQC(
        bytes32 indexed attestationDigest,
        uint64 timestampEpoch,
        address indexed provider,
        bytes32 indexed consentCommitment,
        bytes32 nullifier,
        bool hasDilithium
    );

    event BatchAttested(
        bytes32 indexed batchMerkleRoot,
        uint256 runCount,
        address indexed sidecar
    );

    event GovernanceHalt(address indexed triggeredBy, bytes32 reasonHash);

    modifier onlySafeMode() {
        if (isL0Halted) revert("L0_HALT: Protocol suspended by Phase Mirror");
        _;
    }

    error InvalidProof();
    error Mismatch();
    error Revoked();
    error NotProvider();
    error Replay();
    error InvalidDilithiumSignature();
    error InvalidDilithiumPublicKey();

    constructor(address consentV, address attestV, address batchV, address consentReg, address initialDilithiumVerifier) {
        consentVerifier = IGroth16Verifier(consentV);
        attestationVerifier = IGroth16Verifier(attestV);
        batchVerifier = IHalo2Verifier(batchV);
        consentRegistry = IConsentRegistryView(consentReg);
        dilithiumVerifier = IDilithiumVerifier(initialDilithiumVerifier);
        emit VerifiersSet(consentV, attestV, batchV);
        emit ConsentRegistrySet(consentReg);
        emit DilithiumVerifierSet(initialDilithiumVerifier);
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

    function setDilithiumVerifier(address verifier) external {
        dilithiumVerifier = IDilithiumVerifier(verifier);
        emit DilithiumVerifierSet(verifier);
    }

    function registerDilithiumKey(bytes calldata publicKey) external {
        dilithiumPublicKeys[msg.sender] = publicKey;
        emit DilithiumKeyRegistered(msg.sender, publicKey);
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
    ) external onlySafeMode {
        if (!consentVerifier.verifyProof(cA, cB, cC, consentPub)) revert InvalidProof();
        if (!attestationVerifier.verifyProof(aA, aB, aC, attestPub)) revert InvalidProof();

        if (consentPub[2] != attestPub[1]) revert Mismatch();
        if (consentPub[7] != attestPub[3]) revert Mismatch();

        bytes32 digest = bytes32(attestPub[0]);
        uint64 timestamp = uint64(attestPub[2]);
        bytes32 msgHash = keccak256(abi.encodePacked(digest, timestamp));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(msgHash);
        address signer = ECDSA.recover(ethSignedHash, signature);
        if (!providerAllowed[signer]) revert NotProvider();

        if (uint256(uint160(signer)) != attestPub[1]) revert Mismatch();

        if (address(consentRegistry) != address(0)) {
            if (consentRegistry.revoked(bytes32(consentPub[9]))) revert Revoked();
        }
        bytes32 nullifier = bytes32(attestPub[4]);
        if (usedNullifier[nullifier]) revert Replay();
        usedNullifier[nullifier] = true;

        emit Attested(digest, timestamp, signer, bytes32(attestPub[3]), nullifier);
    }

    /// @notice Submits an attestation with optional Dilithium5 dual-signature (ADR-PML-051).
    function submitAttestationWithDilithium(
        uint256[2] calldata cA,
        uint256[2][2] calldata cB,
        uint256[2] calldata cC,
        uint256[10] calldata consentPub,
        uint256[2] calldata aA,
        uint256[2][2] calldata aB,
        uint256[2] calldata aC,
        uint256[5] calldata attestPub,
        bytes calldata signature,
        bytes calldata dilithiumSignature
    ) external onlySafeMode {
        if (!consentVerifier.verifyProof(cA, cB, cC, consentPub)) revert InvalidProof();
        if (!attestationVerifier.verifyProof(aA, aB, aC, attestPub)) revert InvalidProof();

        if (consentPub[2] != attestPub[1]) revert Mismatch();
        if (consentPub[7] != attestPub[3]) revert Mismatch();

        bytes32 digest = bytes32(attestPub[0]);
        uint64 timestamp = uint64(attestPub[2]);
        bytes32 msgHash = keccak256(abi.encodePacked(digest, timestamp));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(msgHash);
        address signer = ECDSA.recover(ethSignedHash, signature);
        if (!providerAllowed[signer]) revert NotProvider();

        if (uint256(uint160(signer)) != attestPub[1]) revert Mismatch();

        // ADR-PML-051: verify Dilithium if provided.
        if (dilithiumSignature.length > 0) {
            if (address(dilithiumVerifier) == address(0)) revert InvalidDilithiumSignature();
            bytes memory storedPk = dilithiumPublicKeys[signer];
            if (storedPk.length == 0) revert InvalidDilithiumPublicKey();
            if (!dilithiumVerifier.verify(signer, msgHash, dilithiumSignature)) revert InvalidDilithiumSignature();
        }

        if (address(consentRegistry) != address(0)) {
            if (consentRegistry.revoked(bytes32(consentPub[9]))) revert Revoked();
        }
        bytes32 nullifier = bytes32(attestPub[4]);
        if (usedNullifier[nullifier]) revert Replay();
        usedNullifier[nullifier] = true;

        emit AttestedPQC(digest, timestamp, signer, bytes32(attestPub[3]), nullifier, dilithiumSignature.length > 0);
    }

    function _computeMerkleRoot(BatchRunData[] calldata runs) internal pure returns (bytes32) {
        bytes32 currentHash = bytes32(0);
        for (uint256 i = 0; i < runs.length; i++) {
            currentHash = keccak256(abi.encodePacked(currentHash, runs[i].digest, runs[i].timestamp, runs[i].consentCommitment, runs[i].nullifier));
        }
        return currentHash;
    }

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
                if (consentRegistry.revoked(runs[i].consentCommitment)) revert Revoked();
            }
            if (usedNullifier[runs[i].nullifier]) revert Replay();
            usedNullifier[runs[i].nullifier] = true;
            
            emit Attested(runs[i].digest, runs[i].timestamp, sidecar, runs[i].consentCommitment, runs[i].nullifier);
        }
        
        emit BatchAttested(batchMerkleRoot, runs.length, sidecar);
    }

    function triggerL0Halt(bytes32 reasonHash) external {
        if (!authorizedSidecars[msg.sender]) revert NotProvider();
        isL0Halted = true;
        emit GovernanceHalt(msg.sender, reasonHash);
    }
}
