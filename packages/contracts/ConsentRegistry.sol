// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "./utils/Ownable.sol";
import {IGroth16Verifier} from "./interfaces/IGroth16Verifier.sol";
 

/// @title ConsentRegistry
/// @notice Verifies consent proofs and emits audit events. No PHI stored.
contract ConsentRegistry is Ownable {
    IGroth16Verifier public verifier; // consent circuit verifier

    // Optional drift guard. Max server/client skew allowed when checking now_epoch.
    uint256 public maxDrift = 600; // seconds

    // Valid Merkle roots for versioned consent sets (optional).
    mapping(bytes32 => bool) public validRoot;

    // Revocation by nullifier. If true, proofs with this nullifier are rejected.
    mapping(bytes32 => bool) public revoked;

    event VerifierSet(address verifier);
    event MaxDriftSet(uint256 seconds_);
    event RootSet(bytes32 indexed root, bool enabled);
    event Revoked(bytes32 indexed nullifier);

    event ConsentProved(
        bytes32 indexed nullifier,
        uint32 purposeId,
        uint256 scopeHash,
        uint256 providerPk,
        uint256 patientPk,
        uint64 expiryEpoch,
        uint64 nowEpoch
    );

    error InvalidProof();
    error InvalidRoot();
    error RevokedNullifier();
    error ExcessiveDrift();

    constructor(address owner_) Ownable(owner_) {}

    function setVerifier(address v) external onlyOwner {
        verifier = IGroth16Verifier(v);
        emit VerifierSet(v);
    }

    function setMaxDrift(uint256 seconds_) external onlyOwner {
        maxDrift = seconds_;
        emit MaxDriftSet(seconds_);
    }

    function setRoot(bytes32 root, bool enabled) external onlyOwner {
        validRoot[root] = enabled;
        emit RootSet(root, enabled);
    }

    function revoke(bytes32 nullifier_) external onlyOwner {
        revoked[nullifier_] = true;
        emit Revoked(nullifier_);
    }

    /// @dev Public signals order must match the consent.circom declaration.
    /// pub[0]=purpose_id, [1]=scope_hash, [2]=provider_pk, [3]=patient_pk,
    /// [4]=expiry_epoch, [5]=now_epoch, [6]=delta_bound, [7]=consent_commitment,
    /// [8]=consent_root, [9]=nullifier
    function submitConsent(
        uint256[2] calldata pA,
        uint256[2][2] calldata pB,
        uint256[2] calldata pC,
        uint256[10] calldata pub
    ) external {
        require(address(verifier) != address(0), "verifier-not-set");
        // fixed-size pub (10) expected by generated verifier

        // Basic local checks in addition to SNARK constraints
        uint64 nowEpoch = uint64(pub[5]);
        uint64 deltaBound = uint64(pub[6]);
        if (_absDiff(block.timestamp, nowEpoch) > _min(deltaBound, uint64(maxDrift))) revert ExcessiveDrift();

        bytes32 root = bytes32(pub[8]);
        if (root != bytes32(0) && !validRoot[root]) revert InvalidRoot();

        bytes32 nullifier = bytes32(pub[9]);
        if (revoked[nullifier]) revert RevokedNullifier();

        bool ok = verifier.verifyProof(pA, pB, pC, pub);
        if (!ok) revert InvalidProof();

        emit ConsentProved(
            nullifier,
            uint32(pub[0]),
            pub[1],
            pub[2],
            pub[3],
            uint64(pub[4]),
            nowEpoch
        );
    }

    function _absDiff(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    function _min(uint64 a, uint64 b) private pure returns (uint64) {
        return a < b ? a : b;
    }
}
