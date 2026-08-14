//! Mirror of `isPrime_correct` (Multiplicity/NumberTheory.lean witness
//! `isPrimeCorrectWitness`): the executable trial-division test agrees with
//! the elementary definition `n ≥ 2 ∧ no d ∈ [2, n) divides n`, on a bounded
//! domain.

use multiplicity_primes::is_prime;

#[kani::proof]
#[kani::unwind(200)]
fn is_prime_correct() {
    let n: u64 = kani::any();
    kani::assume(n < 200);
    assert_eq!(is_prime(n), (n >= 2) && (2..n).all(|d| n % d != 0));
}
