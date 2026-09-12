// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Common interface for contracts that consume Λ-Trace hashes.
/// @dev Follows MTPI / Web4 principles: prime-lawful, zero-surveillance, auditable
interface ILambdaLTraceConsumer {
    /// @dev Emitted when a new Λ-Trace is linked to an on-chain object.
    event LTraceLinked(bytes32 indexed ltraceHash, address indexed actor, uint256 indexed tokenId);

    /// @notice Returns true if a given Λ-Trace hash has been linked for this token.
    function hasLTrace(uint256 tokenId, bytes32 ltraceHash) external view returns (bool);
}
