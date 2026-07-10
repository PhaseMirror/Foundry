// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal RISC0 mock verifier used only in tests — does not revert
contract MockRisc0 {
  function verify(bytes calldata, bytes32, bytes32) external pure {
    // intentionally no-op; success signalled by not reverting
  }
}
