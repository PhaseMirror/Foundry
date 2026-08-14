//! Kani harnesses for `ramanujan_multiplicity::primes`.

use crate::{is_prime, valuation, prime_factors, factor_product};

/// `is_prime` agrees with trial division on 2..100.
#[cfg(kani)]
#[kani::proof]
fn verify_is_prime_small() {
    let n: u64 = kani::any();
    kani::assume(n >= 2 && n <= 100);
    let brute = trial_prime(n);
    kani::assert(is_prime(n) == brute, "is_prime agrees with trial division");
}

fn trial_prime(n: u64) -> bool {
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

/// `valuation(p, p^k) = k` for k ≤ 10.
#[cfg(kani)]
#[kani::proof]
fn verify_valuation_of_power() {
    let p: u64 = kani::any();
    let k: u64 = kani::any();
    kani::assume(p >= 2 && p <= 100);
    kani::assume(k >= 1 && k <= 10);
    if let Some(pk) = p.checked_pow(k as u32) {
        kani::assert(valuation(p, pk) == k, "valuation(p, p^k) = k");
    }
}

/// `factor_product(prime_factors(n)) = n` for n ≤ 1000.
#[cfg(kani)]
#[kani::proof]
fn verify_factorization_reconstruction() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= 1000);
    let fs = prime_factors(n);
    kani::assert(factor_product(&fs) == n, "factor_product(prime_factors(n)) = n");
}

/// `valuation(p, 0) = 0` for all p.
#[cfg(kani)]
#[kani::proof]
fn verify_valuation_zero() {
    let p: u64 = kani::any();
    kani::assume(p >= 2 && p <= 100);
    kani::assert(valuation(p, 0) == 0, "valuation(p, 0) = 0");
}
