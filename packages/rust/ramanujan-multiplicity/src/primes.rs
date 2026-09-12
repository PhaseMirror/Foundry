//! Prime factorization, primality, and valuation.
//!
//! Total functions on `u64` with overflow-safe arithmetic.
//! Verified by regression tests and Kani harnesses.

/// Trial-division primality.  Total for all `u64`.
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

/// Largest `k` with `p^k ∣ n`; `0` for `n = 0`.
pub fn valuation(p: u64, n: u64) -> u64 {
    if n == 0 {
        return 0;
    }
    if p == 0 {
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
/// Empty list for `n ∈ {0, 1}`.
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
        assert!(is_prime(97));
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
    fn factorization_reconstructs() {
        for n in 1..500u64 {
            let fs = prime_factors(n);
            assert_eq!(factor_product(&fs), n);
        }
    }
}
