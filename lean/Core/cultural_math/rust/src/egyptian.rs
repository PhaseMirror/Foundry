//! Egyptian Multiplication
//!
//! Implements the ancient Egyptian method of multiplication
//! using doubling and addition.
//!
//! Specification: result = a * b

/// Egyptian multiplication algorithm.
///
/// # Arguments
/// * `a` - First operand (non-negative)
/// * `b` - Second operand (non-negative)
///
/// # Returns
/// * `a * b`
///
/// # Example
/// ```
/// let result = cultural_math::egyptian_mul(3, 4);
/// assert_eq!(result, 12);
/// ```
pub fn egyptian_mul(a: u64, b: u64) -> u64 {
    let mut result = 0;
    let mut a = a;
    let mut b = b;
    
    while b > 0 {
        if b % 2 == 1 {
            result += a;
        }
        a *= 2;
        b /= 2;
    }
    
    result
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_egyptian_mul() {
        assert_eq!(egyptian_mul(3, 4), 12);
        assert_eq!(egyptian_mul(5, 6), 30);
        assert_eq!(egyptian_mul(0, 100), 0);
        assert_eq!(egyptian_mul(100, 0), 0);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;
    use kani::*;
    
    #[kani::proof]
    fn verify_egyptian_mul() {
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        kani::assume(a < 1000);
        kani::assume(b < 1000);
        
        let result = egyptian_mul(a, b);
        assert!(result == a * b);
    }
}
