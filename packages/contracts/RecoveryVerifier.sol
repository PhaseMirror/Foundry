// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./interfaces/IVerifier.sol";

/// @title RecoveryVerifier
/// @notice Minimal stand-in verifier for tests and local dev.
/// @dev Implements IVerifier but does not perform real zk verification.
contract RecoveryVerifier is IVerifier {
    function verifyProof(
        uint256[2] memory,        // a
        uint256[2][2] memory,     // b
        uint256[2] memory,        // c
        uint256[] memory          // input
    ) external pure override returns (bool) {
        // For now always succeed – deterministic and cheap.
        return true;
    }
}
