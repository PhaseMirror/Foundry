// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "./utils/Ownable.sol";

/**
 * @title FinalityTracker
 * @notice Tracks on-chain finality status for the Lambda-Proof protocol.
 * @dev Allows authoritative or protocol-driven finality checkpoints.
 */
contract FinalityTracker is Ownable {
    uint64 public latestFinalizedBlock;
    uint256 public constant DEFAULT_FINALITY_DEPTH = 12; // Standard depth for some EVM chains

    event FinalityUpdated(uint64 indexed blockNumber, bytes32 indexed blockHash);

    constructor(address initialOwner) Ownable(initialOwner) {
        latestFinalizedBlock = uint64(block.number);
    }

    /**
     * @notice Updates the latest finalized block.
     * @param blockNumber The block number that is now considered finalized.
     * @param blockHash The block hash of the finalized block.
     */
    function updateFinality(uint64 blockNumber, bytes32 blockHash) external onlyOwner {
        require(blockNumber > latestFinalizedBlock, "Finality: must move forward");
        require(blockNumber <= block.number, "Finality: cannot finalize future block");
        
        latestFinalizedBlock = blockNumber;
        emit FinalityUpdated(blockNumber, blockHash);
    }

    /**
     * @notice Checks if a specific block is considered finalized.
     * @param blockNumber The block number to check.
     */
    function isFinalized(uint64 blockNumber) external view returns (bool) {
        return blockNumber <= latestFinalizedBlock;
    }
    
    /**
     * @notice Returns the depth of a block from the latest finalized block.
     * @param blockNumber The block number to check depth for.
     */
    function getFinalityDepth(uint64 blockNumber) external view returns (uint256) {
        if (blockNumber > block.number) return 0;
        return block.number - blockNumber;
    }
}
