//! Kani harnesses for `ramanujan_multiplicity::entropy`.

use crate::{multiplicity_entropy, multiplicity_profile};

/// `H_M(n) ≥ 0` for all `n ≥ 1`.
#[cfg(kani)]
#[kani::proof]
fn verify_entropy_nonnegative() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= 200);
    let e = multiplicity_entropy(n);
    kani::assert(e >= 0.0, "entropy non-negative");
}

/// `H_M(p) = 0` for any prime `p`.
#[cfg(kani)]
#[kani::proof]
fn verify_entropy_of_prime_is_zero() {
    let p: u64 = kani::any();
    kani::assume(p >= 2 && p <= 100);
    if is_prime_kani(p) {
        kani::assert(multiplicity_entropy(p) == 0.0, "entropy of prime is 0");
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

/// `multiplicity_profile(n)` reconstructs to `n`.
#[cfg(kani)]
#[kani::proof]
fn verify_profile_reconstruction() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= 200);
    let profile = multiplicity_profile(n);
    let mut product: u64 = 1;
    for (p, k) in &profile {
        for _ in 0..*k {
            product = product.saturating_mul(*p);
        }
    }
    kani::assert(product == n, "profile reconstructs to n");
}

/// Entropy is finite for all `n ≥ 1`.
#[cfg(kani)]
#[kani::proof]
fn verify_entropy_finite() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= 200);
    let e = multiplicity_entropy(n);
    kani::assert(e.is_finite(), "entropy is finite");
}
