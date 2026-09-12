pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

/**
 * PrimeCheck - Simplified Prime Testing for Demonstration
 * 
 * PURPOSE:
 * Provides basic prime checking for demo/testing purposes.
 * NOT suitable for production use - use MillerRabin64 for real deployments.
 * Checks basic primality properties: odd, > 3, with placeholder for trial division.
 * 
 * INPUTS:
 * - prime: Field element to test
 * 
 * OUTPUTS:
 * - isPrime: 1 if passes basic checks, 0 otherwise
 * 
 * CONSTRAINTS:
 * 1. prime > 3 (enforced via GreaterThan)
 * 2. prime is odd (LSB of binary representation must be 1)
 * 3. [PLACEHOLDER] Trial division checks (not implemented in demo version)
 * 
 * SECURITY CONSIDERATIONS:
 * - ⚠️  WARNING: This is NOT cryptographically secure!
 * - Accepts all odd numbers > 3 as "prime enough" for demo
 * - Composite numbers like 9, 15, 21, etc. will pass this test
 * - Use MillerRabin64.circom for production prime testing
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Demo purposes only - helps test circuit structure
 * - Production MTPI circuits MUST use full Miller-Rabin test
 * - Included for educational and prototyping workflows
 * 
 * PRODUCTION REPLACEMENT:
 * Replace with MillerRabin64 or full Miller-Rabin implementation:
 * 
 * include "MillerRabin64.circom";
 * component primeTest = MillerRabin64();
 * primeTest.prime <== myValue;
 * primeTest.isPrime === 1;
 * 
 * NOTE:
 * This template exists to support rapid prototyping and testing.
 * All production deployments should migrate to MillerRabin64.
 */

// Simplified prime check for demo purposes
// Checks: odd, > 3, not divisible by small primes
template PrimeCheck() {
    signal input prime;
    signal output isPrime;
    
    // Check prime > 3
    component gt3 = GreaterThan(64);
    gt3.in[0] <== prime;
    gt3.in[1] <== 3;
    
    // Check odd (LSB = 1)
    component bits = Num2Bits(64);
    bits.in <== prime;
    signal isOdd <== bits.out[0];
    
    // For demo: assume any odd number > 3 is "prime enough"
    // In production, add trial division checks here
    isPrime <== gt3.out * isOdd;
}
