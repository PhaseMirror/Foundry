// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IDilithiumVerifier
/// @notice Interface for on-chain Dilithium5 signature verification.
interface IDilithiumVerifier {
    /// @notice Register a Dilithium5 public key for the caller.
    /// @param publicKey 1312-byte Dilithium5 public key.
    function registerPublicKey(bytes calldata publicKey) external;

    /// @notice Verify a Dilithium5 signature over `messageHash` signed by the owner of `publicKey`.
    /// @param owner Address whose registered public key should be used.
    /// @param messageHash The 32-byte message hash that was signed.
    /// @param signature 2420-byte Dilithium5 detached signature.
    /// @return True if the signature is valid for the owner's registered public key.
    function verify(address owner, bytes32 messageHash, bytes calldata signature) external view returns (bool);

    /// @notice Set the precompile address used for production verification.
    /// @param precompile Address of the native Dilithium precompile (or external verifier).
    function setPrecompile(address precompile) external;

    /// @notice Toggle mock mode (accepts any well-formed signature for testnet).
    /// @param mockMode True to enable mock verification.
    function setMockMode(bool mockMode) external;

    /// @notice Current precompile address (0 = mock/unset).
    function precompile() external view returns (address);

    /// @notice True if mock mode is active.
    function mockMode() external view returns (bool);
}
