//! Port of `multiplicity/math/core_math.py`.
//!
//! The Python module uses `sympy.primefactors` / `sympy.factorint` and
//! `numpy.log`. This port reproduces the same semantics exactly using integer
//! factorization by trial division. The only float used is the same
//! `Λ_m` constant and the same log-based comparison in `lawful`.

use std::collections::BTreeMap;

/// Universal Multiplicity Constant (fallback value).
pub const LAMBDA_M: f64 = 1.61803398875;

/// Return the current dynamic `Λ_m` constant.
pub fn get_lambda_m() -> f64 {
    LAMBDA_M
}

/// Factor `n` into primes with exponents, mirroring `sympy.factorint`.
///
/// Returns e.g. `factor_exponents(12) == {2: 2, 3: 1}`.
pub fn factor_exponents(n: u64) -> BTreeMap<u64, u64> {
    let mut remaining = n;
    let mut out = BTreeMap::new();
    let mut divisor: u64 = 2;
    while divisor.saturating_mul(divisor) <= remaining {
        while remaining.is_multiple_of(divisor) {
            *out.entry(divisor).or_insert(0) += 1;
            remaining /= divisor;
        }
        divisor += if divisor == 2 { 1 } else { 2 };
    }
    if remaining > 1 {
        *out.entry(remaining).or_insert(0) += 1;
    }
    out
}

/// The distinct prime factors of `n`, mirroring `sympy.primefactors`.
pub fn prime_factors(n: u64) -> Vec<u64> {
    let mut remaining = n;
    let mut out = Vec::new();
    let mut divisor: u64 = 2;
    while divisor.saturating_mul(divisor) <= remaining {
        if remaining.is_multiple_of(divisor) {
            out.push(divisor);
            while remaining.is_multiple_of(divisor) {
                remaining /= divisor;
            }
        }
        divisor += if divisor == 2 { 1 } else { 2 };
    }
    if remaining > 1 {
        out.push(remaining);
    }
    out
}

/// Check whether `n` is prime-lawful: all `v_p(n) <= log_p(Λ_m)`.
///
/// Mirrors `lawful(n)` in `core_math.py`. For the canonical `Λ_m = φ` this
/// admits only `n <= 1` (every prime power exceeds `φ ≈ 1.618`).
pub fn lawful(n: u64) -> bool {
    lawful_with_lambda(n, LAMBDA_M)
}

/// `lawful` against a caller-supplied `Λ` (as the Python bridge does when a
/// dynamic constant is available).
pub fn lawful_with_lambda(n: u64, lambda_m: f64) -> bool {
    if n <= 1 {
        return true;
    }
    for (prime, exponent) in factor_exponents(n) {
        let bound = lambda_m.ln() / (prime as f64).ln();
        if exponent as f64 > bound {
            return false;
        }
    }
    true
}

/// Entropic complexity `S_p(n)` = sum of p-adic depths.
///
/// Mirrors `entropy(n)` in `core_math.py`. The Python form returns a float;
/// the quantity is integral, so this port returns a `u64`.
pub fn entropy(n: u64) -> u64 {
    if n <= 1 {
        return 0;
    }
    factor_exponents(n).values().sum()
}

/// Recursive factorization loop for stability (`Ξ(n, depth)`).
///
/// Repeatedly replaces `n` by the product of its distinct prime factors
/// (`primefactors`), stopping at a fixed point or after `depth` iterations.
pub fn xi(n: u64, depth: usize) -> u64 {
    if n <= 1 {
        return n;
    }
    let mut current = n;
    for _ in 0..depth {
        let recomposed = prime_factors(current).into_iter().product::<u64>();
        if recomposed == current {
            break;
        }
        current = recomposed;
    }
    current
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn lambda_m_is_phi() {
        assert!((get_lambda_m() - 1.61803398875).abs() < f64::EPSILON);
    }

    #[test]
    fn lawful_matches_phi_bound() {
        assert!(lawful(1));
        assert!(lawful(0));
        // 2^1 = 2 > φ, so any even n is unlawful.
        assert!(!lawful(2));
        assert!(!lawful(3));
        assert!(!lawful(12));
        assert!(!lawful(97));
    }

    #[test]
    fn lawful_with_larger_lambda() {
        // With Λ = 2.0, 2^1 = 2 <= 2 is lawful; 4 = 2^2 > 2 is not.
        assert!(lawful_with_lambda(2, 2.0));
        assert!(!lawful_with_lambda(4, 2.0));
        // With Λ = 2.5: 2^1 <= 2.5 is lawful, 12 = 2^2·3 has 4 > 2.5.
        assert!(lawful_with_lambda(2, 2.5));
        assert!(!lawful_with_lambda(12, 2.5));
    }

    #[test]
    fn entropy_sums_p_adic_depths() {
        assert_eq!(entropy(1), 0);
        assert_eq!(entropy(12), 3); // 2^2 * 3
        assert_eq!(entropy(97), 1);
        assert_eq!(entropy(36), 4); // 2^2 * 3^2
    }

    #[test]
    fn xi_reaches_squarefree_fixpoint() {
        assert_eq!(xi(12, 5), 6); // 12 -> (2*3)=6 -> 6
        assert_eq!(xi(36, 5), 6); // 36 -> 6 -> 6
        assert_eq!(xi(97, 5), 97); // already squarefree
        assert_eq!(xi(1, 5), 1);
        // depth exhaustion still returns last value
        assert_eq!(xi(16, 1), 2);
    }

    #[test]
    fn prime_factors_are_distinct_and_sorted() {
        assert_eq!(prime_factors(12), vec![2, 3]);
        assert_eq!(prime_factors(64), vec![2]);
        assert_eq!(prime_factors(1), Vec::<u64>::new());
        assert_eq!(prime_factors(2 * 97), vec![2, 97]);
    }
}
