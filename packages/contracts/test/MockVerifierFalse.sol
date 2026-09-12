// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal failing mock verifier used only for tests that assert verification failure
contract MockVerifierFalse {
  // Match the DeviceAttest verifyProof signature (uint256[2], uint256[2][2], uint256[2], uint256[5])
  function verifyProof(uint256[2] calldata, uint256[2][2] calldata, uint256[2] calldata, uint256[5] calldata) external pure returns (bool) {
    return false;
  }
}
