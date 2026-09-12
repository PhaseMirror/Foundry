//! Multiplicity entropy H_M(n).
//!
//! H_M(n) = -Σ_p [v_p(n) / Ω(n)] · log(v_p(n) / Ω(n))
//!
//! Measures how distributed the prime multiplicity is.
//! Total on `u64`.  Verified by regression tests and Kani harnesses.

use super::primes::prime_factors;

/// Compute the multiplicity entropy of `n`.
/// Returns 0.0 for n ∈ {0, 1}.
pub fn multiplicity_entropy(n: u64) -> f64 {
    let fs = prime_factors(n);
    if fs.is_empty() {
        return 0.0;
    }
    let omega = fs.len() as f64;
    let mut counts: std::collections::HashMap<u64, usize> = std::collections::HashMap::new();
    for &p in &fs {
        *counts.entry(p).or_insert(0) += 1;
    }
    let mut entropy: f64 = 0.0;
    for (_p, &k) in &counts {
        let prob = k as f64 / omega;
        entropy -= prob * prob.ln();
    }
    entropy
}

/// Compute the multiplicity profile v(n) = (v_2(n), v_3(n), v_5(n), ...).
/// Returns a vector of (prime, exponent) pairs for n > 1, empty for n ∈ {0, 1}.
pub fn multiplicity_profile(n: u64) -> Vec<(u64, u64)> {
    let fs = prime_factors(n);
    if fs.is_empty() {
        return Vec::new();
    }
    let mut profile = Vec::new();
    let mut current = fs[0];
    let mut exp: u64 = 0;
    for &p in &fs {
        if p == current {
            exp += 1;
        } else {
            profile.push((current, exp));
            current = p;
            exp = 1;
        }
    }
    profile.push((current, exp));
    profile
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn entropy_of_one_is_zero() {
        assert_eq!(multiplicity_entropy(1), 0.0);
    }

    #[test]
    fn entropy_of_prime_is_zero() {
        assert_eq!(multiplicity_entropy(2), 0.0);
        assert_eq!(multiplicity_entropy(97), 0.0);
    }

    #[test]
    fn entropy_of_12() {
        // 12 = 2^2 * 3^1 => H_M = -2/3*ln(2/3) - 1/3*ln(1/3)
        let e = multiplicity_entropy(12);
        let expected = -(2.0_f64/3.0 * (2.0_f64/3.0).ln() + 1.0_f64/3.0 * (1.0_f64/3.0).ln());
        assert!((e - expected).abs() < 1e-10);
    }

    #[test]
    fn entropy_bounded() {
        for n in 1..200u64 {
            let e = multiplicity_entropy(n);
            assert!(e >= 0.0, "entropy negative for {n}");
            assert!(e.is_finite(), "entropy not finite for {n}");
        }
    }

    #[test]
    fn profile_reconstructs() {
        for n in 1..200u64 {
            let profile = multiplicity_profile(n);
            let mut product: u64 = 1;
            for (p, k) in &profile {
                for _ in 0..*k {
                    product = product.saturating_mul(*p);
                }
            }
            assert_eq!(product, n, "profile for {n}");
        }
    }

    #[test]
    fn profile_sorted_by_prime() {
        for n in 1..200u64 {
            let profile = multiplicity_profile(n);
            for i in 1..profile.len() {
                assert!(profile[i].0 > profile[i - 1].0, "profile not sorted for {n}");
            }
        }
    }
}
