// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockVerifier {
  function verifyProof(
    uint256[2] memory,
    uint256[2][2] memory,
    uint256[2] memory,
    uint256[] memory
  ) external pure returns (bool r) {
    return true; // always accept
  }

  // Fixed-size overloads used by generated verifier contracts
  function verifyProof(uint256[2] memory, uint256[2][2] memory, uint256[2] memory, uint256[1] memory) external pure returns (bool) { return true; }
  function verifyProof(uint256[2] memory, uint256[2][2] memory, uint256[2] memory, uint256[4] memory) external pure returns (bool) { return true; }
  function verifyProof(uint256[2] memory, uint256[2][2] memory, uint256[2] memory, uint256[5] memory) external pure returns (bool) { return true; }
  function verifyProof(uint256[2] memory, uint256[2][2] memory, uint256[2] memory, uint256[6] memory) external pure returns (bool) { return true; }
  function verifyProof(uint256[2] memory, uint256[2][2] memory, uint256[2] memory, uint256[9] memory) external pure returns (bool) { return true; }
  function verifyProof(uint256[2] memory, uint256[2][2] memory, uint256[2] memory, uint256[10] memory) external pure returns (bool) { return true; }
}
