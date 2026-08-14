// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IStarkVerifier
 * @notice Canonical STARK verifier interface (Spec-aligned).
 */
interface IStarkVerifier {
    /// @notice Returns the pinned manifest hash.
    function pinnedManifest() external view returns (bytes32);

    /**
     * @notice Verify a proof against the pinned manifest hash.
     * @param proof STARK proof bytes (opaque to caller)
     * @param manifestHash_ Expected manifest hash (must equal pinnedManifest())
     * @param pub Public inputs for the circuit
     * @return ok True if verification succeeded
     */
    function verify(bytes calldata proof, bytes32 manifestHash_, uint256[] calldata pub)
        external
        view
        returns (bool ok);
}
