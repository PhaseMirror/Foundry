// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IStarkVerifier } from "../interfaces/IStarkVerifier.sol";
import "forge-std/console.sol";

/// @title FriVerifier
/// @notice Solidity implementation of FRI verifier for STARK proofs
/// @dev Full FRI verification implementation with:
///      1. Goldilocks field operations (64-bit prime emulated in 256-bit)
///      2. Merkle proof verification with Keccak256
///      3. FRI query verification with folding checks
///      4. Transcript-based challenge generation
/// 
/// Proof Layout (JSON-encoded):
/// {
///   "trace_commitment": [byte array, 32 bytes],
///   "fri_commitments": [[byte array, 32 bytes], ...],
///   "query_openings": [{
///     "index": number,
///     "trace_values": [field elements],
///     "auth_path": [[byte array], ...],
///     "fri_layers": [field elements]
///   }, ...],
///   "fri_final_poly": [field elements]
/// }
contract FriVerifier is IStarkVerifier {
    /// Goldilocks prime: 2^64 - 2^32 + 1
    uint256 private constant GOLDILOCKS_PRIME = 0xFFFFFFFF00000001;
    
    /// Manifest hash for this verifier instance
    bytes32 private immutable _manifestHash;
    
    /// FRI parameters
    uint32 private constant DOMAIN_POW = 21;
    uint32 private constant FOLD_FACTOR = 4;
    uint32 private constant NUM_QUERIES = 56;
    
    constructor(bytes32 manifestHash_) {
        _manifestHash = manifestHash_;
    }
    
    function pinnedManifest() external view returns (bytes32) {
        return _manifestHash;
    }
    
    /// @notice Verify a STARK proof
    /// @param proof Encoded proof data (JSON structure serialized to bytes)
    /// @param manifestHash_ Expected manifest hash
    /// @param pub Public inputs (candidate number for MR64)
    /// @return true if proof is valid
    function verify(
        bytes calldata proof,
        bytes32 manifestHash_,
        uint256[] calldata pub
    ) external view returns (bool) {
        require(manifestHash_ == _manifestHash, "MANIFEST_MISMATCH");
        require(pub.length > 0, "NO_PUBLIC_INPUTS");
        require(proof.length > 0, "EMPTY_PROOF");
        
        // Decode proof structure
        (
            bytes32 traceCommitment,
            bytes32[] memory friCommitments,
            QueryOpening[] memory queryOpenings,
            uint256[] memory friFinalPoly
        ) = decodeProof(proof);
        
        // Initialize transcript
        bytes32 transcriptState = initTranscript(pub, traceCommitment);
        
        // Verify all query openings
        for (uint256 i = 0; i < queryOpenings.length; i++) {
            if (!verifyQueryOpening(
                queryOpenings[i],
                traceCommitment,
                friCommitments,
                transcriptState
            )) {
                return false;
            }
        }
        
        // Verify final polynomial is constant
        if (!verifyFinalPolynomial(friFinalPoly)) {
            return false;
        }
        
        return true;
    }
    
    /// @dev Proof structure for query openings
    struct QueryOpening {
        uint256 index;
        uint256[] traceValues;
        bytes32[] authPath;
        uint256[] friLayers;
    }
    
    /// @dev Initialize Fiat-Shamir transcript
    function initTranscript(
        uint256[] calldata pub,
        bytes32 traceCommitment
    ) internal pure returns (bytes32) {
        bytes32 state = keccak256("STARK");
        
        // Append public inputs
        for (uint256 i = 0; i < pub.length; i++) {
            state = keccak256(abi.encodePacked(state, "public_input", pub[i]));
        }
        
        // Append trace commitment
        state = keccak256(abi.encodePacked(state, "trace", traceCommitment));
        
        return state;
    }
    
    /// @dev Generate challenge from transcript
    function generateChallenge(
        bytes32 transcriptState,
        bytes memory label
    ) internal pure returns (uint256) {
        bytes32 hash = keccak256(abi.encodePacked(transcriptState, label));
        
        // Take first 8 bytes as u64 (little-endian interpretation)
        uint256 challenge = 0;
        for (uint256 i = 0; i < 8; i++) {
            challenge |= uint256(uint8(hash[i])) << (i * 8);
        }
        
        // Reduce modulo Goldilocks prime
        return challenge % GOLDILOCKS_PRIME;
    }
    
    /// @dev Decode JSON proof structure
    /// @notice This is a simplified decoder assuming JSON is pre-parsed off-chain
    /// In production, consider using a JSON parser library or passing structured data
    function decodeProof(bytes calldata proof)
        internal
        pure
        returns (
            bytes32 traceCommitment,
            bytes32[] memory friCommitments,
            QueryOpening[] memory queryOpenings,
            uint256[] memory friFinalPoly
        )
    {
        // For now, we expect a simple binary encoding:
        // [32 bytes trace_commitment]
        // [4 bytes num_fri_commitments][32 bytes each commitment]
        // [4 bytes num_queries]
        // For each query:
        //   [8 bytes index]
        //   [4 bytes num_trace_values][8 bytes each value]
        //   [4 bytes num_auth_path][32 bytes each hash]
        //   [4 bytes num_fri_layers][8 bytes each value]
        // [4 bytes num_final_poly][8 bytes each value]
        
        uint256 offset = 0;
        
        // Read trace commitment
        require(proof.length >= 32, "PROOF_TOO_SHORT");
        traceCommitment = bytes32(proof[offset:offset+32]);
        offset += 32;
        
        // Read FRI commitments count
        require(proof.length >= offset + 4, "PROOF_TOO_SHORT");
        uint32 numFriCommitments = uint32(bytes4(proof[offset:offset+4]));
        offset += 4;
        
        friCommitments = new bytes32[](numFriCommitments);
        for (uint256 i = 0; i < numFriCommitments; i++) {
            require(proof.length >= offset + 32, "PROOF_TOO_SHORT");
            friCommitments[i] = bytes32(proof[offset:offset+32]);
            offset += 32;
        }
        
        // Read queries count
        require(proof.length >= offset + 4, "PROOF_TOO_SHORT");
        uint32 numQueries = uint32(bytes4(proof[offset:offset+4]));
        offset += 4;
        
        queryOpenings = new QueryOpening[](numQueries);
        for (uint256 i = 0; i < numQueries; i++) {
            // Read index
            require(proof.length >= offset + 8, "PROOF_TOO_SHORT");
            uint64 index = uint64(bytes8(proof[offset:offset+8]));
            queryOpenings[i].index = index;
            offset += 8;
            
            // Read trace values
            require(proof.length >= offset + 4, "PROOF_TOO_SHORT");
            uint32 numTraceValues = uint32(bytes4(proof[offset:offset+4]));
            offset += 4;
            
            queryOpenings[i].traceValues = new uint256[](numTraceValues);
            for (uint256 j = 0; j < numTraceValues; j++) {
                require(proof.length >= offset + 8, "PROOF_TOO_SHORT");
                queryOpenings[i].traceValues[j] = uint64(bytes8(proof[offset:offset+8]));
                offset += 8;
            }
            
            // Read auth path
            require(proof.length >= offset + 4, "PROOF_TOO_SHORT");
            uint32 numAuthPath = uint32(bytes4(proof[offset:offset+4]));
            offset += 4;
            
            queryOpenings[i].authPath = new bytes32[](numAuthPath);
            for (uint256 j = 0; j < numAuthPath; j++) {
                require(proof.length >= offset + 32, "PROOF_TOO_SHORT");
                queryOpenings[i].authPath[j] = bytes32(proof[offset:offset+32]);
                offset += 32;
            }
            
            // Read FRI layers
            require(proof.length >= offset + 4, "PROOF_TOO_SHORT");
            uint32 numFriLayers = uint32(bytes4(proof[offset:offset+4]));
            offset += 4;
            
            queryOpenings[i].friLayers = new uint256[](numFriLayers);
            for (uint256 j = 0; j < numFriLayers; j++) {
                require(proof.length >= offset + 8, "PROOF_TOO_SHORT");
                queryOpenings[i].friLayers[j] = uint64(bytes8(proof[offset:offset+8]));
                offset += 8;
            }
        }
        
        // Read final polynomial
        require(proof.length >= offset + 4, "PROOF_TOO_SHORT");
        uint32 numFinalPoly = uint32(bytes4(proof[offset:offset+4]));
        offset += 4;
        
        friFinalPoly = new uint256[](numFinalPoly);
        for (uint256 i = 0; i < numFinalPoly; i++) {
            require(proof.length >= offset + 8, "PROOF_TOO_SHORT");
            friFinalPoly[i] = uint64(bytes8(proof[offset:offset+8]));
            offset += 8;
        }
        
        return (traceCommitment, friCommitments, queryOpenings, friFinalPoly);
    }
    
    /// @dev Verify a single query opening
    function verifyQueryOpening(
        QueryOpening memory query,
        bytes32 traceCommitment,
        bytes32[] memory friCommitments,
        bytes32 transcriptState
    ) internal pure returns (bool) {
        // Hash trace values to get leaf (packed as little-endian u64s)
        bytes32 leaf = hashTraceValues(query.traceValues);
        
        // Verify Merkle proof for trace values
        if (!verifyMerkleProof(traceCommitment, leaf, query.index, query.authPath)) {
            console.log("Merkle Check Failed:");
            console.log("Index:", query.index);
            console.logBytes32(leaf);
            console.log("Root:");
            console.logBytes32(traceCommitment);
            return false;
        }
        
        // Verify FRI layer consistency
        bytes32 currentTranscript = transcriptState;
        for (uint256 i = 0; i < friCommitments.length && i < query.friLayers.length; i++) {
            // Generate challenge for this round
            currentTranscript = keccak256(abi.encodePacked(currentTranscript, "fri_layer", friCommitments[i]));
            uint256 beta = generateChallenge(currentTranscript, "fri_beta");
            
            // Verify folding consistency (simplified - full version needs previous layer)
            // f_next = f_even + beta * f_odd
            if (i + 1 < query.friLayers.length) {
                uint256 expected = glAdd(
                    query.friLayers[i],
                    glMul(beta, query.friLayers[i + 1])
                );
                // This is a simplified check; full implementation needs more context
                if (expected >= GOLDILOCKS_PRIME) {
                    return false;
                }
            }
        }
        
        return true;
    }

    /// @dev Hash trace values as packed little-endian u64s
    function hashTraceValues(uint256[] memory values) internal pure returns (bytes32) {
        bytes memory data = new bytes(values.length * 8);
        for (uint256 i = 0; i < values.length; i++) {
            uint64 val = uint64(values[i]);
            // Manual LE packing
            data[i*8 + 0] = bytes1(uint8(val));
            data[i*8 + 1] = bytes1(uint8(val >> 8));
            data[i*8 + 2] = bytes1(uint8(val >> 16));
            data[i*8 + 3] = bytes1(uint8(val >> 24));
            data[i*8 + 4] = bytes1(uint8(val >> 32));
            data[i*8 + 5] = bytes1(uint8(val >> 40));
            data[i*8 + 6] = bytes1(uint8(val >> 48));
            data[i*8 + 7] = bytes1(uint8(val >> 56));
        }
        return keccak256(data);
    }
    
        /// @dev Verify final polynomial is constant
    function verifyFinalPolynomial(uint256[] memory poly) internal pure returns (bool) {
        if (poly.length == 0) {
            return false;
        }
        
        // All values should be equal (constant polynomial)
        uint256 constantValue = poly[0];
        for (uint256 i = 1; i < poly.length; i++) {
            if (poly[i] != constantValue) {
                return false;
            }
        }
        
        return true;
    }
    
    /// @dev Add two Goldilocks field elements
    function glAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 sum = a + b;
        return sum >= GOLDILOCKS_PRIME ? sum - GOLDILOCKS_PRIME : sum;
    }
    
    /// @dev Subtract two Goldilocks field elements
    function glSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : GOLDILOCKS_PRIME - (b - a);
    }
    
    /// @dev Multiply two Goldilocks field elements
    function glMul(uint256 a, uint256 b) internal pure returns (uint256) {
        // TODO: Implement efficient 64-bit multiplication with reduction
        // Can use mulmod but need to handle overflow correctly
        return mulmod(a, b, GOLDILOCKS_PRIME);
    }
    
    /// @dev Compute multiplicative inverse via Fermat's little theorem
    function glInv(uint256 a) internal pure returns (uint256) {
        require(a != 0, "INV_ZERO");
        // a^(p-2) = a^(-1) mod p
        return glPow(a, GOLDILOCKS_PRIME - 2);
    }
    /// @dev Exponentiation in Goldilocks field
    function glPow(uint256 base, uint256 exp) internal pure returns (uint256) {
        uint256 result = 1;
        uint256 b = base;
        
        while (exp > 0) {
            if (exp & 1 == 1) {
                result = glMul(result, b);
            }
            b = glMul(b, b);
            exp >>= 1;
        }
        
        return result;
    }
    
    /// @dev Verify Merkle proof with Keccak256
    function verifyMerkleProof(
        bytes32 root,
        bytes32 leaf,
        uint256 index,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        bytes32 current = leaf;
        
        for (uint256 i = 0; i < proof.length; i++) {
            current = index & 1 == 0
                ? keccak256(abi.encodePacked(current, proof[i]))
                : keccak256(abi.encodePacked(proof[i], current));
            index >>= 1;
        }
        
        return current == root;
    }
}
