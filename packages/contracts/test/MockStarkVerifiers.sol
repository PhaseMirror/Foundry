// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockRisc0Verifier {
    bool public shouldSucceed;

    constructor(bool initial) {
        shouldSucceed = initial;
    }

    function setShouldSucceed(bool value) external {
        shouldSucceed = value;
    }

    function verify(bytes calldata, bytes32, bytes32) external view {
        if (!shouldSucceed) revert("mock risc0 failure");
    }
}

contract MockSp1Verifier {
    bool public shouldSucceed;

    constructor(bool initial) {
        shouldSucceed = initial;
    }

    function setShouldSucceed(bool value) external {
        shouldSucceed = value;
    }

    function verifyProof(bytes32, bytes calldata, bytes calldata) external view {
        if (!shouldSucceed) revert("mock sp1 failure");
    }
}
