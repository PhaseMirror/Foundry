// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IGovernance {
    function isApproved(address actor) external view returns (bool);

    function validateTransition(
        bytes32 proofHash,
        uint256 primeIndex,
        uint16 driftBps
    ) external view returns (bool ok);
}
