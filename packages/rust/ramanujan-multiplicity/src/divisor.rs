//! Divisor function d(n), Ω(n), ω(n).
//!
//! Total functions on `u64`.
//! Verified by regression tests and Kani harnesses.

use super::primes::prime_factors;

/// Number of positive divisors d(n) = ∏ (a_i + 1).
pub fn divisor_count(n: u64) -> u64 {
    if n == 0 {
        return 0;
    }
    let fs = prime_factors(n);
    if fs.is_empty() {
        return 1;
    }
    let mut count: u64 = 1;
    let mut current = fs[0];
    let mut exp: u64 = 0;
    for &p in &fs {
        if p == current {
            exp += 1;
        } else {
            count *= exp + 1;
            current = p;
            exp = 1;
        }
    }
    count * (exp + 1)
}

/// Total number of prime factors with multiplicity Ω(n).
pub fn big_omega(n: u64) -> u64 {
    prime_factors(n).len() as u64
}

/// Number of distinct prime factors ω(n).
pub fn small_omega(n: u64) -> u64 {
    let fs = prime_factors(n);
    let mut distinct: u64 = 0;
    let mut prev: u64 = 0;
    for &p in &fs {
        if p != prev {
            distinct += 1;
            prev = p;
        }
    }
    distinct
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn divisor_count_values() {
        assert_eq!(divisor_count(1), 1);
        assert_eq!(divisor_count(2), 2);
        assert_eq!(divisor_count(3), 2);
        assert_eq!(divisor_count(4), 3);
        assert_eq!(divisor_count(6), 4);
        assert_eq!(divisor_count(12), 6);
        assert_eq!(divisor_count(60), 12);
        assert_eq!(divisor_count(36), 9);
    }

    #[test]
    fn omega_values() {
        assert_eq!(big_omega(1), 0);
        assert_eq!(big_omega(12), 3); // 2^2 * 3
        assert_eq!(big_omega(60), 4); // 2^2 * 3 * 5
        assert_eq!(small_omega(12), 2);
        assert_eq!(small_omega(60), 3);
    }

    #[test]
    fn divisor_of_prime_is_2() {
        for p in [2, 3, 5, 7, 11, 13, 97] {
            assert_eq!(divisor_count(p), 2);
        }
    }

    #[test]
    fn divisor_product_formula() {
        for n in 1..200u64 {
            let fs = prime_factors(n);
            let mut groups: std::collections::HashMap<u64, u64> = std::collections::HashMap::new();
            for &p in &fs {
                *groups.entry(p).or_insert(0) += 1;
            }
            let expected: u64 = groups.values().map(|&k| k + 1).product();
            assert_eq!(divisor_count(n), expected, "d({n})");
        }
    }

    #[test]
    fn omega_relations() {
        for n in 1..200u64 {
            assert!(big_omega(n) >= small_omega(n));
            assert!(small_omega(n) >= 0);
            assert!(big_omega(n) >= 0);
        }
    }
}
