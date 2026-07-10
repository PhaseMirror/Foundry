// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "./utils/Ownable.sol";

/**
 * @title ReceiptRegistry
 * @notice Immutable audit log for Lambda-Proof (ΛProof) receipts.
 * @dev Stores proof hashes, nullifiers, and metadata to ensure verifiable on-chain history.
 */
contract ReceiptRegistry is Ownable {
    struct ProofReceipt {
        bytes32 proofHash;
        bytes32 nullifier;
        address submitter;
        uint64 timestamp;
        uint64 blockNumber;
        bytes metadata;
    }

    // Mapping from proof hash to receipt
    mapping(bytes32 => ProofReceipt) public receipts;
    
    // Mapping from nullifier to proof hash (replay protection)
    mapping(bytes32 => bytes32) public nullifiers;

    event ProofRegistered(
        bytes32 indexed proofHash,
        bytes32 indexed nullifier,
        address indexed submitter,
        uint64 timestamp
    );

    error ProofAlreadyRegistered(bytes32 proofHash);
    error NullifierAlreadyUsed(bytes32 nullifier);

    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Registers a new proof receipt.
     * @param proofHash The cryptographic hash of the proof.
     * @param nullifier The nullifier to prevent replay attacks.
     * @param metadata Optional metadata associated with the proof.
     */
    function registerProof(
        bytes32 proofHash,
        bytes32 nullifier,
        bytes calldata metadata
    ) external {
        if (receipts[proofHash].timestamp != 0) revert ProofAlreadyRegistered(proofHash);
        if (nullifiers[nullifier] != bytes32(0)) revert NullifierAlreadyUsed(nullifier);

        receipts[proofHash] = ProofReceipt({
            proofHash: proofHash,
            nullifier: nullifier,
            submitter: msg.sender,
            timestamp: uint64(block.timestamp),
            blockNumber: uint64(block.number),
            metadata: metadata
        });

        nullifiers[nullifier] = proofHash;

        emit ProofRegistered(proofHash, nullifier, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice Checks if a nullifier has been used.
     * @param nullifier The nullifier to check.
     */
    function isNullifierUsed(bytes32 nullifier) external view returns (bool) {
        return nullifiers[nullifier] != bytes32(0);
    }

    /**
     * @notice Retrieves a full receipt by proof hash.
     * @param proofHash The proof hash to lookup.
     */
    function getReceipt(bytes32 proofHash) external view returns (ProofReceipt memory) {
        return receipts[proofHash];
    }
}
