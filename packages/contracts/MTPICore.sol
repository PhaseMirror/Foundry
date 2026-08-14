// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Poseidon.sol";
import "./interfaces/IGovernance.sol";
import "./ReceiptRegistry.sol";
import "./FinalityTracker.sol";

interface IGroth16Verifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input
    ) external view returns (bool);
}

/**
 * @title MTPICore
 * @notice The primary entry point for Lambda-Proof (ΛProof) on-chain verification and settlement.
 * @dev Aligned with Milestone 3 (M3) specifications for EVM on-chain proof anchoring.
 */
contract MTPICore {
    IGroth16Verifier public immutable verifier;
    ReceiptRegistry public immutable receiptRegistry;
    FinalityTracker public immutable finalityTracker;
    
    address public admin;
    bytes32 public currentState;

    event Settlement(
        bytes32 indexed previousState,
        bytes32 indexed newState,
        bytes32 indexed proofHash,
        address submitter
    );

    error InvalidProof();
    error Unauthorized();

    constructor(
        address verifier_,
        address receiptRegistry_,
        address finalityTracker_,
        bytes32 genesisState
    ) {
        verifier = IGroth16Verifier(verifier_);
        receiptRegistry = ReceiptRegistry(receiptRegistry_);
        finalityTracker = FinalityTracker(finalityTracker_);
        currentState = genesisState;
        admin = msg.sender;
    }

    /**
     * @notice Submits a proof for on-chain settlement.
     * @param pA Groth16 proof element A
     * @param pB Groth16 proof element B
     * @param pC Groth16 proof element C
     * @param pub Public signals [newState, ...otherSignals]
     * @param nullifier Replay protection nullifier
     */
    function settle(
        uint256[2] memory pA,
        uint256[2][2] memory pB,
        uint256[2] memory pC,
        uint256[5] memory pub,
        bytes32 nullifier
    ) external {
        // 1. Verify the Groth16 proof
        if (!verifier.verifyProof(pA, pB, pC, pub)) revert InvalidProof();

        // 2. Register the proof in the ReceiptRegistry (handles anti-replay via nullifier)
        bytes32 proofHash = keccak256(abi.encode(pA, pB, pC, pub));
        receiptRegistry.registerProof(proofHash, nullifier, "");

        // 3. Update the state
        bytes32 prevState = currentState;
        bytes32 newState = bytes32(pub[0]);
        currentState = newState;

        emit Settlement(prevState, newState, proofHash, msg.sender);
    }

    /**
     * @notice Helper to check if a proof is finalized.
     * @param proofHash The hash of the proof to check.
     */
    function isProofFinalized(bytes32 proofHash) external view returns (bool) {
        ReceiptRegistry.ProofReceipt memory receipt = receiptRegistry.getReceipt(proofHash);
        if (receipt.timestamp == 0) return false;
        return finalityTracker.isFinalized(receipt.blockNumber);
    }
}
