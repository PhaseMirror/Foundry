//! Kani harnesses for `ramanujan_multiplicity::divisor`.

use crate::{divisor_count, big_omega, small_omega, prime_factors};

/// `d(n) ≥ 1` for all `n ≥ 1`.
#[cfg(kani)]
#[kani::proof]
fn verify_divisor_count_positive() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= 1000);
    kani::assert(divisor_count(n) >= 1, "d(n) >= 1");
}

/// `d(1) = 1`.
#[cfg(kani)]
#[kani::proof]
fn verify_divisor_of_one() {
    kani::assert(divisor_count(1) == 1, "d(1) = 1");
}

/// `d(p) = 2` for prime p.
#[cfg(kani)]
#[kani::proof]
fn verify_divisor_of_prime() {
    let p: u64 = kani::any();
    kani::assume(p >= 2 && p <= 100);
    // Use the same primality test as the crate
    if is_prime_kani(p) {
        kani::assert(divisor_count(p) == 2, "d(p) = 2 for prime p");
    }
}

fn is_prime_kani(n: u64) -> bool {
    if n < 2 {
        return false;
    }
    if n == 2 {
        return true;
    }
    if n % 2 == 0 {
        return false;
    }
    let mut d: u64 = 3;
    while d <= n / d {
        if n % d == 0 {
            return false;
        }
        d += 2;
    }
    true
}

/// `Ω(n) = Σ v_p(n)` (total prime factors).
#[cfg(kani)]
#[kani::proof]
fn verify_big_omega_sum_of_valuations() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= 200);
    let fs = prime_factors(n);
    kani::assert(big_omega(n) == fs.len() as u64, "Ω(n) = len(prime_factors(n))");
}

/// `ω(n) ≤ Ω(n)` (distinct ≤ total).
#[cfg(kani)]
#[kani::proof]
fn verify_omega_inequality() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= 200);
    kani::assert(small_omega(n) <= big_omega(n), "ω(n) <= Ω(n)");
}
