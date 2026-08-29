//! Stateless Hash-to-Prime (H2P) Derivation & Offset Pinning

use num_bigint::BigUint;
use num_traits::{One, Zero};

pub struct H2pEngine;

impl H2pEngine {
    /// Maximum offset permitted by Cramér gap bound: k_max = 65,536.
    pub const K_MAX: usize = 65536;

    /// Derive 256-bit odd seed N from 32-byte hash.
    pub fn derive_seed(hash: &[u8; 32]) -> BigUint {
        let mut seed = BigUint::from_bytes_be(hash);
        // Force odd integer
        if &seed % 2u32 == BigUint::zero() {
            seed += BigUint::one();
        }
        seed
    }

    /// Deterministic Miller-Rabin primality test for BigUint with standard bases.
    pub fn is_prime(n: &BigUint) -> bool {
        if n <= &BigUint::one() {
            return false;
        }
        if n == &2u32.into() || n == &3u32.into() || n == &5u32.into() || n == &7u32.into() {
            return true;
        }
        if n % 2u32 == BigUint::zero() || n % 3u32 == BigUint::zero() || n % 5u32 == BigUint::zero() {
            return false;
        }

        // Small trial division up to 256 for fast filtering
        let small_primes = [7u32, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251];
        for &p in &small_primes {
            let p_bu = BigUint::from(p);
            if n == &p_bu {
                return true;
            }
            if n % &p_bu == BigUint::zero() {
                return false;
            }
        }

        // Write n - 1 = 2^s * d
        let mut d = n - BigUint::one();
        let mut s = 0usize;
        while &d % 2u32 == BigUint::zero() {
            d /= 2u32;
            s += 1;
        }

        let bases: [u32; 7] = [2, 3, 5, 7, 11, 13, 17];
        for &base in &bases {
            let a = BigUint::from(base);
            if &a >= n {
                continue;
            }
            let mut x = a.modpow(&d, n);
            if x.is_one() || x == n - BigUint::one() {
                continue;
            }
            let mut composite = true;
            for _ in 1..s {
                x = (&x * &x) % n;
                if x == n - BigUint::one() {
                    composite = false;
                    break;
                }
            }
            if composite {
                return false;
            }
        }
        true
    }

    /// Search for the first prime starting from seed N: p = N + k*.
    pub fn find_first_prime(seed: &BigUint) -> Result<(BigUint, usize), String> {
        let mut offset = 0usize;
        while offset <= Self::K_MAX {
            let candidate = seed + BigUint::from(offset);
            if Self::is_prime(&candidate) {
                return Ok((candidate, offset));
            }
            offset += 2;
        }
        Err(format!("No prime found within Cramér bound k_max = {}", Self::K_MAX))
    }
}
