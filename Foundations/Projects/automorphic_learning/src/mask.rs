use num_bigint::BigUint;
use num_traits::{One, Zero};
use std::ops::Rem;

/// Compute the Legendre symbol (a|p) for prime `p`.
/// Returns 0 if a ≡ 0 (mod p), 1 if a is a quadratic residue, -1 otherwise.
pub fn legendre_symbol(a: usize, p: usize) -> i8 {
    if a % p == 0 {
        return 0;
    }
    // Euler's criterion: a^{(p-1)/2} mod p
    let exp = (p - 1) / 2;
    let mut result = 1usize;
    let mut base = a % p;
    let mut e = exp;
    while e > 0 {
        if e % 2 == 1 {
            result = (result * base) % p;
        }
        base = (base * base) % p;
        e /= 2;
    }
    if result == 1 {
        1
    } else if result == p - 1 {
        -1
    } else {
        0 // should not happen for prime p
    }
}

/// Residue mask: a matrix `p × p` where entry (i,j) is true iff
/// `legendre_symbol(i - j, p) == 1`.
pub fn residue_mask(p: usize) -> Vec<Vec<bool>> {
    let mut mask = vec![vec![false; p]; p];
    for i in 0..p {
        for j in 0..p {
            let diff = (i + p - j) % p; // (i - j) mod p
            mask[i][j] = legendre_symbol(diff, p) == 1;
        }
    }
    mask
}

#[cfg(test)]
mod tests {
    use super::*;
    #[kani::proof]
    fn test_legendre_symbol() {
        // prime 7, test a few values
        let p = 7usize;
        assert_eq!(legendre_symbol(0, p), 0);
        assert_eq!(legendre_symbol(1, p), 1);
        assert_eq!(legendre_symbol(2, p), 1);
        assert_eq!(legendre_symbol(3, p), -1);
    }

    #[kani::proof]
    fn test_residue_mask() {
        let p = 5usize;
        let m = residue_mask(p);
        // Verify size
        assert_eq!(m.len(), p);
        for row in &m {
            assert_eq!(row.len(), p);
        }
        // Spot check a known entry: for p=5, (1-4)=2 is a residue -> true
        assert!(m[1][4]);
    }
}
