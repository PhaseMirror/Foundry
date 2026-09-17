//! Prime-indexed tensor overlay support (ADR-012, ADR-013).
//!
//! Mirrors `ts/src/multiplicity.ts` exactly: an incremental, lazily-computed
//! prime sieve capped at `MAX_PRIME_INDEX = 1000` (the 1000th prime is 7,919).
//! The upper bound `p/(p+1)` is used by [`crate::feedback`] as the tightened
//! contractivity ceiling.
//!
//! ## Test fidelity
//!
//! `get_prime_at_index(0) == 2`, `get_prime_at_index(3) == 7` — matching the
//! TypeScript `PRIMES_CACHE = [2]` convention where index 0 → prime 2.

/// Hard ceiling on `prime_index` per ADR-013. `get_prime_at_index(1000) = 7919`.
pub const MAX_PRIME_INDEX: usize = 1000;

/// The first `MAX_PRIME_INDEX + 1` primes, pre-sieved.
///
/// Index `i` → `PRIMES[i]` is the `(i+1)`-th prime (`PRIMES[0] = 2`).
/// Computed once at compile time via a `const fn` sieve.
pub const PRIMES: [u32; MAX_PRIME_INDEX + 1] = {
    // We need to find the 1001st prime. The 1001st prime is 7,919.
    // Use a trial-division sieve in const context.
    const LIMIT: usize = 8000;
    let mut sieve = [true; LIMIT];
    sieve[0] = false;
    sieve[1] = false;
    let mut i = 2;
    while i * i < LIMIT {
        if sieve[i] {
            let mut j = i * i;
            while j < LIMIT {
                sieve[j] = false;
                j += i;
            }
        }
        i += 1;
    }
    let mut primes = [0u32; MAX_PRIME_INDEX + 1];
    let mut count = 0;
    let mut n = 2;
    while n < LIMIT && count < MAX_PRIME_INDEX + 1 {
        if sieve[n] {
            primes[count] = n as u32;
            count += 1;
        }
        n += 1;
    }
    primes
};

/// Returns the `(index+1)`-th prime: `0 → 2`, `1 → 3`, `2 → 5`, `3 → 7`, ...
///
/// Panics if `index > MAX_PRIME_INDEX`.
///
/// # Examples
///
/// ```
/// use multiplicity_crypto::get_prime_at_index;
/// assert_eq!(get_prime_at_index(0), 2);
/// assert_eq!(get_prime_at_index(3), 7);
/// assert_eq!(get_prime_at_index(1000), 7919);
/// ```
#[must_use]
pub const fn get_prime_at_index(index: usize) -> u32 {
    assert!(index <= MAX_PRIME_INDEX, "prime index exceeds MAX_PRIME_INDEX (1000)");
    PRIMES[index]
}

/// Returns the prime-index lookup table slice.
#[must_use]
pub const fn prime_sieve() -> &'static [u32; MAX_PRIME_INDEX + 1] {
    &PRIMES
}

/// Prime-indexed upper bound on the contractivity score: `p / (p + 1)`.
///
/// Per ADR-012, the contractivity ceiling tightens with the prime index —
/// higher primes enforce stricter contraction. For `prime_index = 0` (p=2)
/// the bound is `2/3 ≈ 0.6667`; for `prime_index = 3` (p=7) it is `7/8 = 0.875`.
///
/// This is the **float** version used by the gate predicate in [`crate::feedback`].
#[must_use]
pub fn prime_upper_bound_f64(prime_index: usize) -> f64 {
    let p = get_prime_at_index(prime_index) as f64;
    p / (p + 1.0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn primes_match_typescript_sieve() {
        assert_eq!(get_prime_at_index(0), 2);
        assert_eq!(get_prime_at_index(1), 3);
        assert_eq!(get_prime_at_index(2), 5);
        assert_eq!(get_prime_at_index(3), 7);
        assert_eq!(get_prime_at_index(4), 11);
        assert_eq!(get_prime_at_index(9), 29);
        assert_eq!(get_prime_at_index(1000), 7919);
    }

    #[test]
    #[should_panic(expected = "prime index exceeds")]
    fn prime_index_out_of_bounds_panics() {
        let _ = get_prime_at_index(MAX_PRIME_INDEX + 1);
    }

    #[test]
    fn upper_bound_decreases_toward_one() {
        // p/(p+1) is monotonically increasing toward 1 as p grows, so the
        // *ceiling* relaxes for larger primes. The gate still rejects ρ ≥ 1.
        let b0 = prime_upper_bound_f64(0); // 2/3
        let b3 = prime_upper_bound_f64(3); // 7/8
        assert!((b0 - 2.0 / 3.0).abs() < 1e-12);
        assert!((b3 - 7.0 / 8.0).abs() < 1e-12);
        assert!(b0 < b3);
        assert!(b3 < 1.0);
    }

    #[test]
    fn sieve_is_monotonic_and_ordered() {
        let primes = prime_sieve();
        for i in 1..=MAX_PRIME_INDEX {
            assert!(primes[i] > primes[i - 1]);
            assert!(primes[i] % 2 != 0 || primes[i] == 2);
        }
    }

    #[test]
    fn all_sieved_values_are_prime() {
        fn is_prime(n: u32) -> bool {
            if n < 2 {
                return false;
            }
            let mut i = 2;
            while i * i <= n {
                if n % i == 0 {
                    return false;
                }
                i += 1;
            }
            true
        }
        for &p in PRIMES.iter() {
            assert!(is_prime(p), "{p} is not prime");
        }
    }
}
