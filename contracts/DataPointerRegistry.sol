// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IGroth16Verifier} from "./interfaces/IGroth16Verifier.sol";
 

interface IConsentRegistryView {
    function revoked(bytes32) external view returns (bool);
}

/// @title DataPointerRegistry
/// @notice Verifies a data-pointer proof together with a consent proof and emits an audit event.
/// Storage is minimal; no PHI is stored.
contract DataPointerRegistry {
    IGroth16Verifier public consentVerifier;      // verifier for consent.circom
    IGroth16Verifier public dataPointerVerifier;  // verifier for data_pointer.circom
    IConsentRegistryView public consentRegistry;  // optional revocation view

    event VerifiersSet(address consentV, address pointerV);
    event ConsentRegistrySet(address registry);

    event PointerAuthorized(
        bytes32 indexed pointerCommitment,
        bytes32 indexed consentCommitment,
        uint32 purposeId,
        uint256 scopeHash,
        uint256 providerPk
    );

    error InvalidProof();
    error Mismatch();
    error Revoked();

    constructor(address consentV, address pointerV, address consentReg) {
        consentVerifier = IGroth16Verifier(consentV);
        dataPointerVerifier = IGroth16Verifier(pointerV);
        consentRegistry = IConsentRegistryView(consentReg);
        emit VerifiersSet(consentV, pointerV);
        emit ConsentRegistrySet(consentReg);
    }

    function setVerifiers(address consentV, address pointerV) external {
        // keep simple; protect with auth in production
        consentVerifier = IGroth16Verifier(consentV);
        dataPointerVerifier = IGroth16Verifier(pointerV);
        emit VerifiersSet(consentV, pointerV);
    }

    function setConsentRegistry(address reg) external {
        consentRegistry = IConsentRegistryView(reg);
        emit ConsentRegistrySet(reg);
    }

    /// Inputs:
    ///  - consentPub[0..9] must match ConsentCircuit public ordering
    ///  - pointerPub[0..4] must match DataPointerCircuit ordering
    /// Checks:
    ///  - Both proofs valid
    ///  - purpose_id, scope_hash, provider_pk match across both pubs
    ///  - consent_commitment equals pointerPub[4]
    ///  - consent nullifier not revoked if registry provided
    function submitPointer(
        uint256[2] calldata cA,
        uint256[2][2] calldata cB,
        uint256[2] calldata cC,
        uint256[10] calldata consentPub,
        uint256[2] calldata pA,
        uint256[2][2] calldata pB,
        uint256[2] calldata pC,
        uint256[5] calldata pointerPub
    ) external {
        // fixed-size consentPub (10) and pointerPub (5)

        // 1) Verify proofs
        if (!consentVerifier.verifyProof(cA, cB, cC, consentPub)) revert InvalidProof();
        if (!dataPointerVerifier.verifyProof(pA, pB, pC, pointerPub)) revert InvalidProof();

        // 2) Cross-proof linkage checks
        // consent: [0]=purpose_id [1]=scope_hash [2]=provider_pk [7]=consent_commitment [9]=nullifier
        // pointer: [0]=purpose_id [1]=scope_hash [2]=provider_pk [3]=pointer_commitment [4]=consent_commitment
        if (consentPub[0] != pointerPub[0]) revert Mismatch();
        if (consentPub[1] != pointerPub[1]) revert Mismatch();
        if (consentPub[2] != pointerPub[2]) revert Mismatch();
        if (consentPub[7] != pointerPub[4]) revert Mismatch();

        // 3) Optional revocation guard
        if (address(consentRegistry) != address(0)) {
            bytes32 nullifier = bytes32(consentPub[9]);
            if (consentRegistry.revoked(nullifier)) revert Revoked();
        }

        emit PointerAuthorized(
            bytes32(pointerPub[3]),
            bytes32(pointerPub[4]),
            uint32(pointerPub[0]),
            pointerPub[1],
            pointerPub[2]
        );
    }
}
