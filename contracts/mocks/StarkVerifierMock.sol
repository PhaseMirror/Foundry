// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IStarkVerifier} from "../interfaces/IStarkVerifier.sol";

/**
 * @title StarkVerifierMock
 * @notice Minimal mock aligned to Spec. No header tricks.
 */
contract StarkVerifierMock is IStarkVerifier {
    bytes32 private _pinned;

    constructor(bytes32 manifestHash_) {
        _pinned = manifestHash_;
    }

    function setPinnedManifest(bytes32 mh) external {
        _pinned = mh;
    }

    function pinnedManifest() external view returns (bytes32) {
        return _pinned;
    }

    function verify(bytes calldata /*proof*/, bytes32 manifestHash_, uint256[] calldata /*pub*/)
        external
        view
        returns (bool ok)
    {
        return manifestHash_ == _pinned;
    }
}
