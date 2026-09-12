// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRiscZeroVerifier} from "@risc0/ethereum/IRiscZeroVerifier.sol";

contract ZmtVerifier {
    IRiscZeroVerifier public immutable verifier;
    bytes32 public immutable imageId;

    // The latest verified HS-norm squared (scaled by 1e18 for precision)
    uint256 public latestHsNormSq;
    // Timestamp of the last successful verification
    uint256 public lastVerifiedAt;
    // Receipt hash to avoid replay
    mapping(bytes32 => bool) public verifiedReceipts;

    event HSNormVerified(
        bytes32 indexed receiptHash,
        uint256 hsNormSq,
        uint256 timestamp
    );

    constructor(IRiscZeroVerifier _verifier, bytes32 _imageId) {
        verifier = _verifier;
        imageId = _imageId;
    }

    /**
     * @notice Verify a RISC Zero receipt that attests to the HS-norm squared value.
     * @param receiptBytes The serialized receipt from `stark_receipt.bin`.
     * @param journal The committed journal bytes (the HS-norm scaled by 1e18 as u64 bytes, big-endian).
     */
    function verifyHSNormBound(
        bytes calldata receiptBytes,
        bytes calldata journal
    ) external {
        // Verify the RISC Zero receipt against the guest image ID
        verifier.verify(receiptBytes, imageId, journal);

        // Decode the journal: exactly 8 bytes representing scaled u64 HS-norm squared
        require(journal.length == 8, "Invalid journal length");
        
        uint64 rawHsNormSq;
        assembly {
            // calldataload reads 32 bytes, we shift right by 24 bytes (192 bits) to get the leading 8 bytes
            rawHsNormSq := shr(192, calldataload(journal.offset))
        }
        
        uint256 hsNormSq = uint256(rawHsNormSq);

        // Update state
        bytes32 receiptHash = keccak256(receiptBytes);
        require(!verifiedReceipts[receiptHash], "Receipt already verified");
        verifiedReceipts[receiptHash] = true;
        latestHsNormSq = hsNormSq;
        lastVerifiedAt = block.timestamp;

        emit HSNormVerified(receiptHash, hsNormSq, block.timestamp);
    }
}
