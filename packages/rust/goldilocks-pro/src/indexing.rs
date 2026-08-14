// Canonical PrimeMask and PrimeGated are defined in the `goldilocks` crate.
// Re-exported here for backward compatibility.
pub use goldilocks::PrimeMask;

/// A structure carrying a prime mask.
pub trait PrimeGated {
    fn mask(&self) -> PrimeMask;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_prime_basis() {
        use goldilocks::P_64;
        assert_eq!(P_64[0], 2);
        assert_eq!(P_64[1], 3);
        assert_eq!(P_64[63], 311);
    }

    #[test]
    fn test_mask_algebra() {
        let m2 = PrimeMask::from_bit(0); // 2
        let m3 = PrimeMask::from_bit(1); // 3

        let union = m2.or(&m3);
        assert!(union.is_set(0));
        assert!(union.is_set(1));
        assert_eq!(union.count_ones(), 2);

        let intersection = union.and(&m2);
        assert!(intersection.is_set(0));
        assert!(!intersection.is_set(1));

        let diff = union.xor(&m2);
        assert!(!diff.is_set(0));
        assert!(diff.is_set(1));
    }
}
