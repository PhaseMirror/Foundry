pragma circom 2.1.6;

include "MillerRabin64.circom";

/**
 * MillerRabin - Compatibility Wrapper for Prime Testing
 * 
 * PURPOSE:
 * Provides backward-compatible interface to MillerRabin64 for existing circuits.
 * Simplifies prime testing in circuits that expect single-template interface.
 * 
 * This is a LIBRARY TEMPLATE (no main component) for use in other circuits.
 * 
 * INPUTS:
 * - prime: Field element to test for primality
 * 
 * OUTPUTS:
 * - isPrime: 1 if prime passes Miller-Rabin test, 0 otherwise
 * 
 * IMPLEMENTATION:
 * Delegates to MillerRabin64 which implements deterministic 64-bit primality testing
 * using trial division and Fermat test (simplified version).
 * 
 * SECURITY CONSIDERATIONS:
 * - Safe for primes < 2^64 when using full MillerRabin64 implementation
 * - Current simplified implementation uses single Fermat test for demonstration
 * - Production use requires full Miller-Rabin with multiple bases
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Prime gates are fundamental to MTPI addressing and identity
 * - Enables Web4 prime-indexed identity without trusted oracles
 * - Cryptographic primality enforced in-circuit (zero-knowledge prime gate)
 */

// Wrapper for compatibility with existing code
template MillerRabin() {
    signal input prime;
    signal output isPrime;
    
    component mr = MillerRabin64();
    mr.prime <== prime;
    isPrime <== mr.isPrime;
}

component main = MillerRabin();
