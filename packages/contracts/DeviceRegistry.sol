// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "./utils/Ownable.sol";
import {IGroth16Verifier} from "./interfaces/IGroth16Verifier.sol";
 

/// @title DeviceRegistry
/// @notice Verifies device telemetry proofs, enforces allowed device roots, drift, and replay protection.
contract DeviceRegistry is Ownable {
    IGroth16Verifier public verifier; // device_attest.circom

    // Allowlist of secure-boot roots
    mapping(bytes32 => bool) public allowedRoot;

    // Replay guard per telemetry
    mapping(bytes32 => bool) public usedNullifier;

    // Drift bound for timestamp_epoch vs block.timestamp
    uint64 public maxDrift = 600; // seconds

    event VerifierSet(address v);
    event RootAllowed(bytes32 root, bool allowed);
    event MaxDriftSet(uint64 seconds_);

    event Telemetry(
        bytes32 indexed deviceRoot,
        bytes32 indexed boundsCommitment,
        uint64 timestampEpoch,
        bytes32 telemetryCommitment,
        bytes32 nullifier
    );

    error InvalidProof();
    error NotAllowedRoot();
    error ExcessiveDrift();
    error Replay();

    constructor(address owner_) Ownable(owner_) {}

    function setVerifier(address v) external onlyOwner {
        verifier = IGroth16Verifier(v);
        emit VerifierSet(v);
    }

    function allowRoot(bytes32 root, bool allowed) external onlyOwner {
        allowedRoot[root] = allowed;
        emit RootAllowed(root, allowed);
    }

    function setMaxDrift(uint64 seconds_) external onlyOwner {
        maxDrift = seconds_;
        emit MaxDriftSet(seconds_);
    }

    /// Public signals order must match circuit:
    /// [0]=device_root [1]=metric_bounds_commitment [2]=timestamp_epoch [3]=telemetry_commitment [4]=telemetry_nullifier
    function submit(
        uint256[2] calldata pA,
        uint256[2][2] calldata pB,
        uint256[2] calldata pC,
        uint256[5] calldata pub
    ) external {
        // fixed-size pub (5) expected by generated verifier
        if (!verifier.verifyProof(pA, pB, pC, pub)) revert InvalidProof();

        bytes32 root = bytes32(pub[0]);
        if (!allowedRoot[root]) revert NotAllowedRoot();

        uint64 ts = uint64(pub[2]);
        uint64 nowTs = uint64(block.timestamp);
        uint64 diff = nowTs > ts ? nowTs - ts : ts - nowTs;
        if (diff > maxDrift) revert ExcessiveDrift();

        bytes32 nul = bytes32(pub[4]);
        if (usedNullifier[nul]) revert Replay();
        usedNullifier[nul] = true;

        emit Telemetry(root, bytes32(pub[1]), ts, bytes32(pub[3]), nul);
    }
}
