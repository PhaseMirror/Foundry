// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IGroth16Verifier} from "./interfaces/IGroth16Verifier.sol";
 

interface IConsentRegistryView {
    function revoked(bytes32) external view returns (bool);
}

/// @title AttestationRegistry
/// @notice Verifies an attestation proof and links it with a valid consent proof; checks provider signature; emits audit event.
contract AttestationRegistry {
    using ECDSA for bytes32;

    IGroth16Verifier public consentVerifier;     // consent.circom
    IGroth16Verifier public attestationVerifier; // attestation.circom
    IConsentRegistryView public consentRegistry; // optional revocation check

    // Allowlisted provider signers
    mapping(address => bool) public providerAllowed;

    // Prevent replays per attestation+patient secret
    mapping(bytes32 => bool) public usedNullifier;

    event VerifiersSet(address consentV, address attestV);
    event ConsentRegistrySet(address reg);
    event ProviderAllowed(address provider, bool allowed);

    event Attested(
        bytes32 indexed attestationDigest,
        uint64 timestampEpoch,
        address indexed provider,
        bytes32 indexed consentCommitment,
        bytes32 nullifier
    );

    error InvalidProof();
    error Mismatch();
    error Revoked();
    error NotProvider();
    error Replay();

    constructor(address consentV, address attestV, address consentReg) {
        consentVerifier = IGroth16Verifier(consentV);
        attestationVerifier = IGroth16Verifier(attestV);
        consentRegistry = IConsentRegistryView(consentReg);
        emit VerifiersSet(consentV, attestV);
        emit ConsentRegistrySet(consentReg);
    }

    function setVerifiers(address consentV, address attestV) external {
        consentVerifier = IGroth16Verifier(consentV);
        attestationVerifier = IGroth16Verifier(attestV);
        emit VerifiersSet(consentV, attestV);
    }

    function setConsentRegistry(address reg) external {
        consentRegistry = IConsentRegistryView(reg);
        emit ConsentRegistrySet(reg);
    }

    function setProvider(address signer, bool allowed) external {
        providerAllowed[signer] = allowed;
        emit ProviderAllowed(signer, allowed);
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
}
