//! Mirror of `prime_two` (Multiplicity/NumberTheory.lean witness
//! `primeTwoWitness`): 2 is prime.

use multiplicity_primes::is_prime;

#[kani::proof]
fn prime_two() {
    assert!(is_prime(2));
}
