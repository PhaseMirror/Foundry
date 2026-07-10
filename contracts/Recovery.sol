// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IVerifier {
    function verifyProof(bytes calldata proof, uint256[4] calldata pub) external view returns (bool);
}

import {Ownable} from "./utils/Ownable.sol";

contract Recovery is Ownable {
    event KeyRotated(bytes32 indexed identityHash, bytes32 indexed newPK, uint256 nonce);

    IVerifier public immutable verifier;
    mapping(bytes32 => uint256) public recoveryNonce;
    uint256 public rotationCooldown = 1 days;
    mapping(bytes32 => uint256) public lastRotationAt;

    constructor(IVerifier _verifier) Ownable(msg.sender) {
        verifier = _verifier;
    }

    function setCooldown(uint256 s) external onlyOwner {
        rotationCooldown = s;
    }

    function nextNonce(bytes32 identityHash) public view returns (uint256) {
        return recoveryNonce[identityHash] + 1;
    }

    function rotate(
        bytes32 identityHash,
        bytes32 newPK,
        bytes calldata proof,
        uint256[4] calldata pubSignals
    ) external {
        uint256 expected = nextNonce(identityHash);
        require(pubSignals[0] == uint256(identityHash), "id mismatch");
        require(pubSignals[1] == uint256(newPK), "pk mismatch");
        require(pubSignals[2] == expected, "bad nonce");
        require(block.timestamp >= lastRotationAt[identityHash] + rotationCooldown, "cooldown");
        require(verifier.verifyProof(proof, pubSignals), "proof");

        recoveryNonce[identityHash] = expected;
        lastRotationAt[identityHash] = block.timestamp;
        emit KeyRotated(identityHash, newPK, expected);
    }
}
