// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IStarkVerifier } from "../interfaces/IStarkVerifier.sol";

/// @notice Regression test verifier that stores manifest in storage
contract StarkVerifierStorage is IStarkVerifier {
    bytes32 private _manifest;

    constructor(bytes32 manifest_) {
        _manifest = manifest_;
    }

    function pinnedManifest() external view returns (bytes32) {
        return _manifest;
    }

    function verify(bytes calldata proof, bytes32 manifestHash, uint256[] calldata /*pub*/)
        external
        view
        returns (bool)
    { return manifestHash == _manifest && proof.length > 0; }
}
