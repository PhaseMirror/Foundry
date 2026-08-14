//! Mirror of `not_prime_zero` / `not_prime_one` (Multiplicity/NumberTheory.lean
//! witness `primeZeroOneWitness`): 0 and 1 are not prime.

use multiplicity_primes::is_prime;

#[kani::proof]
fn prime_zero_one() {
    assert!(!is_prime(0));
    assert!(!is_prime(1));
}
