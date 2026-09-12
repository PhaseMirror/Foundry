// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IPolicyRegistry { function versionHash(uint32) external view returns (bytes32); }

abstract contract UsesPolicy {
    IPolicyRegistry public policyRegistry;
    constructor(IPolicyRegistry reg) { policyRegistry = reg; }
    modifier checkPolicy(uint32 version, bytes32 policyHash) {
        require(policyRegistry.versionHash(version) == policyHash, "policy mismatch");
        _;
    }
}

// Example usage in a verifier/MTPI contract:
// function quantumTransition(..., uint32 policyVersion, bytes32 policyHash, uint256[/*n*/] memory pubSignals) external checkPolicy(policyVersion, policyHash) {
//   require(pubSignals[POLICY_IDX] == uint256(policyHash), "pub policyHash mismatch");
//   // verify proof as usual
// }
