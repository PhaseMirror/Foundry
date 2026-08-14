// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Shared verifier interface used across multiple registry/consumer contracts
interface IGroth16Verifier {
    function verifyProof(uint256[2] calldata pA,uint256[2][2] calldata pB,uint256[2] calldata pC,uint256[] calldata pubSignals) external view returns (bool);
    function verifyProof(uint256[2] calldata pA,uint256[2][2] calldata pB,uint256[2] calldata pC,uint256[1] calldata pubSignals) external view returns (bool);
    function verifyProof(uint256[2] calldata pA,uint256[2][2] calldata pB,uint256[2] calldata pC,uint256[4] calldata pubSignals) external view returns (bool);
    function verifyProof(uint256[2] calldata pA,uint256[2][2] calldata pB,uint256[2] calldata pC,uint256[5] calldata pubSignals) external view returns (bool);
    function verifyProof(uint256[2] calldata pA,uint256[2][2] calldata pB,uint256[2] calldata pC,uint256[6] calldata pubSignals) external view returns (bool);
    function verifyProof(uint256[2] calldata pA,uint256[2][2] calldata pB,uint256[2] calldata pC,uint256[9] calldata pubSignals) external view returns (bool);
    function verifyProof(uint256[2] calldata pA,uint256[2][2] calldata pB,uint256[2] calldata pC,uint256[10] calldata pubSignals) external view returns (bool);
}
