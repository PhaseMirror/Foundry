// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Poseidon {
    function hash(uint256[] memory input) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(input));
    }

    function hashToField(uint256[2] memory inputs) external pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(inputs)));
    }
}
