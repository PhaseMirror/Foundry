//! African Mathematics
//!
//! Implements African mathematical concepts including halving.
//!
//! Specification: result = n / 2

/// African halving operation.
///
/// # Arguments
/// * `n` - Value to halve
///
/// # Returns
/// * `n / 2`
///
/// # Example
/// ```
/// let result = cultural_math::african_halve(8);
/// assert_eq!(result, 4);
/// ```
pub fn african_halve(n: u64) -> u64 {
    n / 2
}

/// Repeated halving until zero.
///
/// # Arguments
/// * `n` - Starting value
///
/// # Returns
/// * Number of halvings needed to reach zero
pub fn halve_converges(n: u64) -> u64 {
    let mut count = 0;
    let mut value = n;
    
    while value > 0 {
        value = african_halve(value);
        count += 1;
    }
    
    count
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_african_halve() {
        assert_eq!(african_halve(8), 4);
        assert_eq!(african_halve(7), 3);
        assert_eq!(african_halve(0), 0);
    }
    
    #[test]
    fn test_halve_converges() {
        assert_eq!(halve_converges(0), 0);
        assert_eq!(halve_converges(1), 1);
        assert_eq!(halve_converges(8), 4);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;
    use kani::*;
    
    #[kani::proof]
    fn verify_african_halve() {
        let n: u64 = kani::any();
        kani::assume(n < 1000);
        
        let result = african_halve(n);
        assert!(result == n / 2);
    }
    
    #[kani::proof]
    fn verify_halve_converges() {
        let n: u64 = kani::any();
        kani::assume(n < 1000);
        
        let count = halve_converges(n);
        // After count halvings, we should reach 0
        let mut value = n;
        for _ in 0..count {
            value = african_halve(value);
        }
        assert!(value == 0);
    }
}
