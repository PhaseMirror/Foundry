// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IStarkVerifier } from "./interfaces/IStarkVerifier.sol";

contract CircuitRegistry {
    address public owner;
    address public verifier;
    bytes32 public pinnedManifest;

    event VerifierPinned(address indexed verifier, bytes32 indexed manifestHash);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error VKHashMismatch();
    error ManifestDrift();
    error Unauthorized();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function setVerifier(address v, bytes32 m) external onlyOwner {
        if (IStarkVerifier(v).pinnedManifest() != m) revert VKHashMismatch();
        verifier = v;
        pinnedManifest = m;
        emit VerifierPinned(v, m);
    }

    function guardedVerify(bytes calldata proof, bytes32 advertisedManifest, uint256[] calldata pub)
        external
        view
        returns (bool)
    {
        if (advertisedManifest != pinnedManifest) revert ManifestDrift();
        return IStarkVerifier(verifier).verify(proof, advertisedManifest, pub);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
