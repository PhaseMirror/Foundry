// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IDilithiumVerifier} from "./IDilithiumVerifier.sol";

/// @title DilithiumVerifier
/// @notice On-chain Dilithium5 signature verification with mock/testnet support.
/// @dev Production deployments should set `precompile` to a native Dilithium precompile
///      address and disable `mockMode`. Testnet/debug can enable `mockMode` to accept
///      any well-formed (correct-length) signature without expensive lattice math.
contract DilithiumVerifier is IDilithiumVerifier {
    // Dilithium5 parameter sizes (from NIST FIPS 204).
    uint256 public constant PK_LEN = 2592;
    uint256 public constant SIG_LEN = 4627;

    mapping(address => bytes) public dilithiumPublicKeys;
    address public precompile;
    bool public mockMode;

    event PublicKeyRegistered(address indexed owner, bytes publicKey);
    event PrecompileSet(address precompile);
    event MockModeSet(bool mockMode);

    error InvalidPublicKeyLength();
    error InvalidSignatureLength();
    error UnregisteredPublicKey();

    function setPrecompile(address _precompile) external {
        precompile = _precompile;
        emit PrecompileSet(_precompile);
    }

    function setMockMode(bool _mockMode) external {
        mockMode = _mockMode;
        emit MockModeSet(_mockMode);
    }

    function registerPublicKey(bytes calldata publicKey) external override {
        if (publicKey.length != PK_LEN) revert InvalidPublicKeyLength();
        dilithiumPublicKeys[msg.sender] = publicKey;
        emit PublicKeyRegistered(msg.sender, publicKey);
    }

    function verify(address owner, bytes32 messageHash, bytes calldata signature) external view override returns (bool) {
        bytes memory pk = dilithiumPublicKeys[owner];
        if (pk.length == 0) revert UnregisteredPublicKey();
        if (signature.length != SIG_LEN) revert InvalidSignatureLength();

        // Testnet / mock path: accept any correctly-sized signature against a registered key.
        if (mockMode) {
            return true;
        }

        // Production path: delegate to a native Dilithium precompile or external verifier.
        // The expected precompile ABI (to be finalized with chain integration):
        //   function verify(bytes calldata pk, bytes32 msgHash, bytes calldata sig) external view returns (bool);
        if (precompile == address(0)) {
            return false;
        }

        // (bool success, bytes memory result) = precompile.staticcall(
        //     abi.encodeWithSelector(bytes4(keccak256("verify(bytes,bytes32,bytes)")), pk, messageHash, signature)
        // );
        // return success && abi.decode(result, (bool));

        // Precompile call commented until chain provides the host function.
        return false;
    }
}
