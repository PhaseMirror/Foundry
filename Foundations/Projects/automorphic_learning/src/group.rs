use num_bigint::BigUint;
use num_traits::{One, Zero};
use std::collections::HashSet;

/// Automorphic group AGL(1, p) acting on `0..p-1`.
#[derive(Clone, Copy, Debug)]
pub struct AutomorphicGroup {
    /// Prime modulus (must be prime).
    pub p: usize,
    /// Multiplicative unit `u` (coprime with `p`).
    pub u: usize,
    /// Translation `k`.
    pub k: usize,
}

/// Action `g • i = (u * i + k) mod p`.
pub fn act(g: &AutomorphicGroup, i: usize) -> usize {
    ((g.u * i + g.k) % g.p)
}

/// Naïve check that `u` is invertible modulo `p`.
pub fn is_coprime(u: usize, p: usize) -> bool {
    let mut a = u as i64;
    let mut b = p as i64;
    while b != 0 {
        let r = a % b;
        a = b;
        b = r;
    }
    a.abs() == 1
}

/// Verify bijectivity for a concrete small prime (used by Kani).
#[cfg(test)]
mod tests {
    use super::*;
    #[kani::proof]
    fn test_act_is_bijective() {
        // small prime for exhaustive test
        let p = 5usize;
        let g = AutomorphicGroup { p, u: 2, k: 3 };
        // ensure u is coprime with p
        assert!(is_coprime(g.u, p));
        let mut seen = [false; 5];
        for i in 0..p {
            let j = act(&g, i);
            assert!(j < p);
            seen[j] = true;
        }
        for b in seen.iter() {
            assert!(*b);
        }
    }
}
