//! Vedic Multiplication
//!
//! Implements Vedic mathematics multiplication techniques.
//!
//! Specification: result = (base + a) * (base + b)

/// Vedic multiplication using base decomposition.
///
/// # Arguments
/// * `a` - First offset from base
/// * `b` - Second offset from base
/// * `base` - Base value
///
/// # Returns
/// * `(base + a) * (base + b)`
///
/// # Example
/// ```
/// let result = cultural_math::vedic_mul(3, 4, 10);
/// assert_eq!(result, 13 * 14);
/// ```
pub fn vedic_mul(a: u64, b: u64, base: u64) -> u64 {
    (base + a) * (base + b)
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_vedic_mul() {
        assert_eq!(vedic_mul(3, 4, 10), 13 * 14);
        assert_eq!(vedic_mul(1, 2, 5), 6 * 7);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;
    use kani::*;
    
    #[kani::proof]
    fn verify_vedic_mul() {
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        let base: u64 = kani::any();
        
        kani::assume(a < 100);
        kani::assume(b < 100);
        kani::assume(base < 1000);
        
        let result = vedic_mul(a, b, base);
        assert!(result == (base + a) * (base + b));
    }
}
