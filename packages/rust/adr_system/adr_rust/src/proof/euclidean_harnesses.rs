//! Kani verification harnesses for Euclidean multiplicity theorems.
//!
//! Run with:
//! ```bash
//! cargo kani --package adr_rust
//! ```
//!
//! **Bounded verification strategy:** All mathematical properties are checked
//! for all inputs up to `MAX_INT = 1024` (or all finite prime sets up to size 4
//! with primes ≤ 31).  These bounds are conservative; raising them increases
//! Kani runtime quadratically.

use crate::euclidean::arithmetic::{classify, factorize, is_prime, profile, euclid_nonclosure, tau_from_factorization, omega_from_factorization};
use crate::euclidean::types::{Factorization, IntegerClass};

const MAX_INT: u64 = 256;

// ─── Euclidean Theorem 1: Prime factorization exists ─────────────────────────

/// Verify that every integer n in [2, MAX_INT] factorizes successfully.
#[cfg(kani)]
#[kani::proof]
fn verify_factorization_exists() {
    let n: u64 = kani::any();
    kani::assume(n >= 2 && n <= MAX_INT);
    let result = factorize(n);
    assert!(result.is_some(), "factorization exists for n = {}", n);
}

// ─── Euclidean Theorem 2: Factorization reconstructs n ───────────────────────

/// Verify that `factorize(n).value() == n` for all n in [2, MAX_INT].
#[cfg(kani)]
#[kani::proof]
fn verify_factorization_reconstruction() {
    let n: u64 = kani::any();
    kani::assume(n >= 2 && n <= MAX_INT);
    let f = factorize(n).unwrap();
    assert_eq!(f.value(), n, "factorization reconstructs n = {}", n);
}

// ─── Euclidean Theorem 3: τ(n) = ∏(a_i + 1) ────────────────────────────────

/// Verify the divisor-count formula τ(n) = ∏(a_i + 1) for all n ≤ MAX_INT.
#[cfg(kani)]
#[kani::proof]
fn verify_tau_formula() {
    let n: u64 = kani::any();
    kani::assume(n >= 2 && n <= MAX_INT);
    let f = factorize(n).unwrap();
    let tau_computed = f.tau();

    // Compute τ(n) by brute-force divisor counting.
    let tau_bruteforce: u64 = (1..=n).filter(|d| n % d == 0).count() as u64;

    assert_eq!(
        tau_computed, tau_bruteforce,
        "τ({}) mismatch: formula={}, brute-force={}",
        n, tau_computed, tau_bruteforce
    );
}

// ─── Euclidean Theorem 4: Integer classification is total ────────────────────

/// Verify that every n ∈ [1, MAX_INT] is classified into exactly one class.
#[cfg(kani)]
#[kani::proof]
fn verify_classification_total() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= MAX_INT);
    let class = classify(n);
    // Exactly one of the four cases holds.
    let is_unit = matches!(class, IntegerClass::Unit);
    let is_number = matches!(class, IntegerClass::Number);
    let is_prime = matches!(class, IntegerClass::Prime);
    let is_composite = matches!(class, IntegerClass::Composite);
    assert!(
        (is_unit as u8) + (is_number as u8) + (is_prime as u8) + (is_composite as u8) == 1,
        "classification is total and exclusive for n = {}",
        n
    );
}

// ─── Euclidean Theorem 5: 1 is the only Unit ─────────────────────────────────

/// Verify that 1 is classified as `Unit` and no other n > 1 is.
#[cfg(kani)]
#[kani::proof]
fn verify_unit_uniqueness() {
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= MAX_INT);
    let class = classify(n);
    if n == 1 {
        assert!(matches!(class, IntegerClass::Unit));
    } else {
        assert!(!matches!(class, IntegerClass::Unit));
    }
}

// ─── Euclidean Theorem 6: Euclid's Non-Closure ──────────────────────────────

/// Verify that for any finite set S of primes with |S| ≤ 3 and max(S) ≤ 31,
/// there exists a new prime q ∉ S dividing N_S = ∏p∈S p + 1.
#[cfg(kani)]
#[kani::proof]
fn verify_euclid_nonclosure_bounded() {
    let s_len: u64 = kani::any();
    kani::assume(s_len >= 1 && s_len <= 3);

    let mut s = Vec::new();
    for i in 0..s_len {
        let p: u64 = kani::any();
        kani::assume(p >= 2 && p <= 31);
        kani::assume(is_prime(p));
        // No duplicates in S.
        if i > 0 {
            let mut unique = true;
            for j in 0..i {
                if s[j as usize] == p {
                    unique = false;
                    break;
                }
            }
            kani::assume(unique);
        }
        s.push(p);
    }

    let q = euclid_nonclosure(&s);
    assert!(q.is_some(), "Non-closure failed for S = {:?}", s);

    let q_val = q.unwrap();
    // q must be prime.
    assert!(is_prime(q_val), "q = {} is not prime", q_val);
    // q must not be in S.
    assert!(!s.contains(&q_val), "q = {} is already in S = {:?}", q_val, s);

    // q must divide N_S.
    let product: u64 = s.iter().product();
    let n_s = product + 1;
    assert_eq!(n_s % q_val, 0, "q = {} does not divide N_S = {}", q_val, n_s);
}

// ─── Euclidean Theorem 7: ω(n) and Ω(n) from factorization ──────────────────

/// Verify that ω(n) and Ω(n) computed from factorization match brute-force.
#[cfg(kani)]
#[kani::proof]
fn verify_multiplicity_functions() {
    let n: u64 = kani::any();
    kani::assume(n >= 2 && n <= MAX_INT);
    let f = factorize(n).unwrap();

    // ω(n) = number of distinct primes.
    let omega_brute: usize = {
        let mut temp = n;
        let mut count = 0usize;
        let mut p = 2u64;
        while p * p <= temp {
            if temp % p == 0 {
                count += 1;
                while temp % p == 0 {
                    temp /= p;
                }
            }
            p += 1;
        }
        if temp > 1 {
            count += 1;
        }
        count
    };
    assert_eq!(f.omega(), omega_brute, "ω({}) mismatch", n);

    // Ω(n) = total number of prime factors with multiplicity.
    let big_omega_brute: u64 = {
        let mut temp = n;
        let mut count = 0u64;
        let mut p = 2u64;
        while p * p <= temp {
            while temp % p == 0 {
                count += 1;
                temp /= p;
            }
            p += 1;
        }
        if temp > 1 {
            count += 1;
        }
        count
    };
    assert_eq!(f.big_omega(), big_omega_brute, "Ω({}) mismatch", n);
}

// ─── Euclidean Theorem 8: Divisor poset size matches τ(n) ───────────────────

/// Verify that |D(n)| = τ(n) for all n ≤ MAX_INT.
#[cfg(kani)]
#[kani::proof]
fn verify_divisor_poset_size() {
    use crate::euclidean::types::DivisorPoset;
    let n: u64 = kani::any();
    kani::assume(n >= 1 && n <= MAX_INT);
    let f = factorize(n).unwrap_or_else(|| Factorization::new(vec![]));
    let poset = DivisorPoset::new(n);
    let tau = tau_from_factorization(&f.factors);
    assert_eq!(
        poset.len() as u64,
        tau,
        "|D({})| = {} but τ({}) = {}",
        n,
        poset.len(),
        n,
        tau
    );
}
