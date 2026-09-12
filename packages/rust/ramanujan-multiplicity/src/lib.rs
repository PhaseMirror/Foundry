//! # Ramanujan Multiplicity Project (ADR-233)
//!
//! Production-grade Rust implementation of the number-theoretic objects
//! introduced in the ADR-233 research program:
//!
//! - Prime factorization and valuation
//! - Divisor function d(n), Ω(n), ω(n)
//! - Multiplicity profile **v**(n)
//! - Multiplicity entropy H_M(n)
//! - Highly composite numbers (HCN)
//! - Ramanujan τ-function
//! - Partition function p(n)
//!
//! Every exported function is total on `u64` and verified by Kani on
//! bounded domains.  No `unsafe`, no black-box algebra, no handwaving.
//!
//! Mirrors: `lean/Ramanujan/Core.lean`, `lean/Ramanujan/Theorems.lean`

pub mod primes;
pub mod divisor;
pub mod hcn;
pub mod entropy;
pub mod tau;
pub mod partitions;

#[cfg(kani)]
pub mod kani;

pub use primes::{is_prime, prime_factors, valuation, factor_product};
pub use divisor::{divisor_count, big_omega, small_omega};
pub use hcn::{is_hcn, next_hcn, hcn_up_to};
pub use entropy::{multiplicity_entropy, multiplicity_profile};
pub use tau::{tau, tau_multiplicative, is_modular_form};
pub use partitions::{partition_count, pentagonal_bound};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_prime_factors_small() {
        assert_eq!(prime_factors(12), vec![2, 2, 3]);
        assert_eq!(prime_factors(97), vec![97]);
        assert_eq!(prime_factors(1), Vec::<u64>::new());
    }

    #[test]
    fn test_tau_multiplicative() {
        assert_eq!(tau_multiplicative(2, 3), tau(2) * tau(3));
        assert_eq!(tau_multiplicative(4, 3), tau(4) * tau(3));
        assert_eq!(tau_multiplicative(2, 5), tau(2) * tau(5));
    }

    #[test]
    fn test_divisor_count_small() {
        assert_eq!(divisor_count(1), 1);
        assert_eq!(divisor_count(2), 2);
        assert_eq!(divisor_count(12), 6);
        assert_eq!(divisor_count(60), 12);
    }

    #[test]
    fn test_big_omega_small() {
        assert_eq!(big_omega(1), 0);
        assert_eq!(big_omega(12), 3); // 2^2 * 3
        assert_eq!(big_omega(60), 4); // 2^2 * 3 * 5
    }

    #[test]
    fn test_small_omega_small() {
        assert_eq!(small_omega(1), 0);
        assert_eq!(small_omega(12), 2); // 2, 3
        assert_eq!(small_omega(60), 3); // 2, 3, 5
    }

    #[test]
    fn test_hcn_small() {
        assert!(is_hcn(1));
        assert!(is_hcn(2));
        assert!(is_hcn(4));
        assert!(is_hcn(6));
        assert!(is_hcn(12));
        assert!(!is_hcn(8));
        assert!(!is_hcn(9));
    }

    #[test]
    fn test_entropy_small() {
        let e12 = multiplicity_entropy(12);
        // 12 = 2^2 * 3^1 => H_M = -2/3*log(2/3) - 1/3*log(1/3)
        let expected = -(2.0_f64/3.0 * (2.0_f64/3.0).ln() + 1.0_f64/3.0 * (1.0_f64/3.0).ln());
        assert!((e12 - expected).abs() < 1e-10);
    }

    #[test]
    fn test_tau_small() {
        assert_eq!(tau(1), 1);
        assert_eq!(tau(2), -24);
        assert_eq!(tau(3), 252);
        assert_eq!(tau(4), -1472);
        assert_eq!(tau(5), -4830);
        assert_eq!(tau(6), 6048);
        assert_eq!(tau(7), -16744);
        assert_eq!(tau(8), 84480);
        assert_eq!(tau(9), -39408);
        assert_eq!(tau(10), -39024);
    }

    #[test]
    fn test_partition_small() {
        assert_eq!(partition_count(0), 1);
        assert_eq!(partition_count(1), 1);
        assert_eq!(partition_count(2), 2);
        assert_eq!(partition_count(3), 3);
        assert_eq!(partition_count(4), 5);
        assert_eq!(partition_count(5), 7);
        assert_eq!(partition_count(10), 42);
    }

    #[test]
    fn test_hcn_up_to_100() {
        let hcns = hcn_up_to(120);
        assert_eq!(hcns, vec![1, 2, 4, 6, 12, 24, 36, 48, 60, 120]);
    }

    #[test]
    fn test_divisor_product_reconstruction() {
        for n in 1..200u64 {
            let fs = prime_factors(n);
            assert_eq!(factor_product(&fs), n);
        }
    }

    #[test]
    fn test_omega_relations() {
        for n in 1..200u64 {
            assert!(big_omega(n) >= small_omega(n), "n={n}");
            assert!(small_omega(n) >= 0);
        }
    }
}
