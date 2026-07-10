use crate::GoldilocksField;

/// Lever 2 — Prime-Gated Indexing (Normative)
/// All structures in Pro-tier MUST carry a valid prime mask.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Default)]
pub struct PrimeMask(pub u64);

impl PrimeMask {
    pub const EMPTY: Self = Self(0);

    /// Canonical 64-Prime Basis P64
    /// Fixed forever and MUST be used verbatim.
    pub const P64: [u32; 64] = [
        2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53,
        59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131,
        137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223,
        227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311,
    ];

    #[inline]
    pub fn from_bit(k: u32) -> Self {
        assert!(k < 64, "Local prime index must be < 64");
        Self(1 << k)
    }

    #[inline]
    pub fn is_set(&self, k: u32) -> bool {
        assert!(k < 64, "Local prime index must be < 64");
        (self.0 & (1 << k)) != 0
    }

    #[inline]
    pub fn and(self, other: Self) -> Self {
        Self(self.0 & other.0)
    }

    #[inline]
    pub fn or(self, other: Self) -> Self {
        Self(self.0 | other.0)
    }

    #[inline]
    pub fn xor(self, other: Self) -> Self {
        Self(self.0 ^ other.0)
    }

    #[inline]
    pub fn count_ones(&self) -> u32 {
        self.0.count_ones()
    }

    /// Interpret the mask directly as a field element in Goldilocks.
    pub fn to_field(&self) -> GoldilocksField {
        GoldilocksField::new(self.0)
    }
}

/// A structure carrying a prime mask.
pub trait PrimeGated {
    fn mask(&self) -> PrimeMask;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_prime_basis() {
        assert_eq!(PrimeMask::P64[0], 2);
        assert_eq!(PrimeMask::P64[1], 3);
        assert_eq!(PrimeMask::P64[63], 311);
    }

    #[test]
    fn test_mask_algebra() {
        let m2 = PrimeMask::from_bit(0); // 2
        let m3 = PrimeMask::from_bit(1); // 3
        
        let union = m2.or(m3);
        assert!(union.is_set(0));
        assert!(union.is_set(1));
        assert_eq!(union.count_ones(), 2);
        
        let intersection = union.and(m2);
        assert!(intersection.is_set(0));
        assert!(!intersection.is_set(1));
        
        let diff = union.xor(m2);
        assert!(!diff.is_set(0));
        assert!(diff.is_set(1));
    }
}
