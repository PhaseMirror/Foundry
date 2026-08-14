pragma circom 2.1.6;

include "MillerRabin64.circom";

/**
 * MillerRabinLib - Library Template for Prime Testing (No Main Component)
 * 
 * PURPOSE:
 * Provides MillerRabin template as a library component for inclusion in other circuits.
 * Identical to MillerRabin.circom but explicitly documented as library-only.
 * 
 * This file should NOT be compiled as a standalone circuit.
 * It is included by other circuits that need prime testing functionality.
 * 
 * USAGE:
 * include "MillerRabinLib.circom";
 * 
 * component primeTest = MillerRabin();
 * primeTest.prime <== myPrimeCandidate;
 * primeTest.isPrime === 1; // Assert primality
 * 
 * INPUTS:
 * - prime: Field element to test for primality
 * 
 * OUTPUTS:
 * - isPrime: 1 if prime passes Miller-Rabin test, 0 otherwise
 * 
 * SECURITY CONSIDERATIONS:
 * - Delegates to MillerRabin64 for actual implementation
 * - See MillerRabin64.circom for detailed security analysis
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Enables modular circuit design (separation of concerns)
 * - Library pattern supports auditable, reusable components
 * - Consistent with MTPI principle of minimal, reviewable changes
 */

// Wrapper for compatibility with existing code (library version without main)
template MillerRabin() {
    signal input prime;
    signal output isPrime;
    
    component mr = MillerRabin64();
    mr.prime <== prime;
    isPrime <== mr.isPrime;
}
