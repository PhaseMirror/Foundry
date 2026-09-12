// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal SP1 mock verifier used only in tests — does not revert
contract MockSp1 {
  function verifyProof(bytes32, bytes calldata, bytes calldata) external pure {
    // intentionally no-op; success signalled by not reverting
  }
}
