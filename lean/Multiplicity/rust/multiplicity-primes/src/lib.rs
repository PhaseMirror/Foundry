//! # Multiplicity Kernel — Primes and factorization (ADR-0001)
//!
//! Mirrors `Spec/Prime.lean` (trial-division primality, agreement with the
//! elementary definition) and `Spec/Factorization.lean` (valuation, factor
//! lists, product reconstruction).
//!
//! Total functions on `u64`: primality uses the overflow-safe test
//! `d ≤ n / d`; the valuation counts powers of `p` dividing `n` with
//! checked multiplication; factorization trial-divides up to `sqrt(n)`.
//!
//! Zero-trust contract: no `unsafe`, no black-box algebra; Kani carries the
//! executable correctness contract on bounded domains and the deterministic
//! regression vectors pin the concrete behaviour.

/// Trial-division primality, mirroring `Spec.Prime.isPrime`.  Total for all
/// `u64`.  Overflow-safe (`d ≤ n / d`, never `d * d`).
pub fn is_prime(n: u64) -> bool {
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

/// Largest `k` with `p ^ k ∣ n`; `0` for `n = 0` (mirrors the kernel
/// convention).  Uses checked multiplication so it is total on `u64`.
pub fn valuation(p: u64, n: u64) -> u64 {
    if n == 0 {
        return 0;
    }
    let mut power: u64 = p;
    let mut k: u64 = 0;
    loop {
        if n % power == 0 {
            k += 1;
            match power.checked_mul(p) {
                Some(next) => power = next,
                None => break,
            }
        } else {
            break;
        }
    }
    k
}

/// Product of a factor list, saturating at `u64::MAX`.
pub fn factor_product(fs: &[u64]) -> u64 {
    let mut acc: u64 = 1;
    for &f in fs {
        acc = acc.saturating_mul(f);
    }
    acc
}

/// Prime factorization of `n` with multiplicity, in increasing order.
/// Total for all `u64`; the empty list is returned for `n ∈ {0, 1}`.
pub fn prime_factors(n: u64) -> Vec<u64> {
    let mut factors = Vec::new();
    let mut m = n;
    let mut d: u64 = 2;
    while d <= m / d {
        while m % d == 0 {
            factors.push(d);
            m /= d;
        }
        d += 1;
    }
    if m > 1 {
        factors.push(m);
    }
    factors
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn prime_small_values() {
        assert!(!is_prime(0));
        assert!(!is_prime(1));
        assert!(is_prime(2));
        assert!(is_prime(3));
        assert!(!is_prime(4));
        assert!(is_prime(5));
        assert!(!is_prime(9));
        assert!(is_prime(17));
        assert!(!is_prime(21));
        assert!(is_prime(97));
        assert!(!is_prime(100));
    }

    #[test]
    fn prime_agrees_with_bruteforce() {
        fn brute(n: u64) -> bool {
            if n < 2 {
                return false;
            }
            for d in 2..n {
                if n % d == 0 {
                    return false;
                }
            }
            true
        }
        for n in 0..200u64 {
            assert_eq!(is_prime(n), brute(n), "is_prime({n})");
        }
    }

    #[test]
    fn valuation_values() {
        assert_eq!(valuation(2, 12), 2);
        assert_eq!(valuation(3, 27), 3);
        assert_eq!(valuation(2, 16), 4);
        assert_eq!(valuation(5, 100), 2);
        assert_eq!(valuation(2, 0), 0);
        assert_eq!(valuation(2, 1), 0);
        assert_eq!(valuation(3, 10), 0);
    }

    #[test]
    fn valuation_of_power_is_exponent() {
        for p in 2..30u64 {
            for k in 0..6u64 {
                if let Some(pk) = p.checked_pow(k as u32) {
                    assert_eq!(valuation(p, pk), k, "valuation({p}, {p}^{k})");
                }
            }
        }
    }

    #[test]
    fn factorization_values() {
        assert_eq!(prime_factors(12), vec![2, 2, 3]);
        assert_eq!(prime_factors(18), vec![2, 3, 3]);
        assert_eq!(prime_factors(97), vec![97]);
        assert_eq!(prime_factors(210), vec![2, 3, 5, 7]);
        assert_eq!(prime_factors(1), Vec::<u64>::new());
        assert_eq!(prime_factors(0), Vec::<u64>::new());
    }

    #[test]
    fn factorization_reconstructs() {
        for n in 1..500u64 {
            let fs = prime_factors(n);
            let product = factor_product(&fs);
            assert_eq!(product, n, "factor_product(prime_factors({n})) = {n}");
        }
    }

    #[test]
    fn factor_product_empty() {
        assert_eq!(factor_product(&[]), 1);
    }

    #[test]
    fn factor_product_values() {
        assert_eq!(factor_product(&[2, 2, 3]), 12);
        assert_eq!(factor_product(&[97]), 97);
    }
}
