//! Pythagorean Triples
//!
//! Generates Pythagorean triples using Euclid's formula.
//!
//! Specification: a² + b² = c²

/// Generate a Pythagorean triple using Euclid's formula.
///
/// # Arguments
/// * `m` - First parameter (> n)
/// * `n` - Second parameter (< m)
///
/// # Returns
/// * `(a, b, c)` such that a² + b² = c²
///
/// # Panics
/// Panics if m <= n
pub fn pythagorean_triple(m: u64, n: u64) -> (u64, u64, u64) {
    assert!(m > n, "m must be greater than n");
    
    let a = m * m - n * n;
    let b = 2 * m * n;
    let c = m * m + n * n;
    
    (a, b, c)
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_pythagorean_triple() {
        let (a, b, c) = pythagorean_triple(2, 1);
        assert_eq!(a, 3);
        assert_eq!(b, 4);
        assert_eq!(c, 5);
        assert_eq!(a * a + b * b, c * c);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;
    use kani::*;
    
    #[kani::proof]
    fn verify_pythagorean_triple() {
        let m: u64 = kani::any();
        let n: u64 = kani::any();
        
        kani::assume(m > n);
        kani::assume(m < 1000);
        kani::assume(n < 1000);
        
        let (a, b, c) = pythagorean_triple(m, n);
        assert!(a * a + b * b == c * c);
    }
}
