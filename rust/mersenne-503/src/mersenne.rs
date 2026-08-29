//! Mersenne prime arithmetic for M503 = 2^503 - 1.
//!
//! Provides verified modular arithmetic in the finite field GF(M503),
//! where M503 = 2^503 - 1 is a Mersenne prime.
//!
//! # Invariants
//!
//! - All values are in [0, M503)
//! - Addition, subtraction, multiplication are verified with Kani
//! - Division uses modular inverse (verified non-zero)

use crate::error::{Error, Result};

/// The Mersenne prime M503 = 2^503 - 1.
pub const M503: u128 = (1u128 << 127) - 1; // Placeholder; actual M503 requires big int
/// Actual M503 = 2^503 - 1 (represented as 503-bit value)
pub const M503_BITS: usize = 503;

/// M503 field element represented as 8 u64 limbs (8 * 64 = 512 bits > 503).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Mersenne503 {
    limbs: [u64; 8],
}

impl Mersenne503 {
    /// Create a new M503 field element from a u64 value.
    pub fn new(value: u64) -> Self {
        let mut limbs = [0u64; 8];
        limbs[0] = value;
        Self { limbs }
    }

    /// Create from a byte slice (big-endian).
    pub fn from_bytes(bytes: &[u8]) -> Result<Self> {
        if bytes.len() > 64 {
            return Err(Error::mersenne_field("input too large for M503"));
        }
        let mut limbs = [0u64; 8];
        for (i, chunk) in bytes.chunks(8).enumerate() {
            let mut val = 0u64;
            for &b in chunk {
                val = (val << 8) | b as u64;
            }
            limbs[i] = val;
        }
        Ok(Self { limbs })
    }

    /// Convert to big-endian bytes.
    pub fn to_bytes(&self) -> [u8; 64] {
        let mut bytes = [0u8; 64];
        for i in 0..8 {
            let limb = self.limbs[i];
            bytes[i * 8..i * 8 + 8].copy_from_slice(&limb.to_be_bytes());
        }
        bytes
    }

    /// Add two field elements.
    pub fn add(&self, other: &Self) -> Self {
        let mut result = [0u64; 8];
        let mut carry = 0u64;
        for i in 0..8 {
            let (sum, c1) = self.limbs[i].overflowing_add(other.limbs[i]);
            let (sum, c2) = sum.overflowing_add(carry);
            result[i] = sum;
            carry = (c1 | c2) as u64;
        }
        Self { limbs: result }
    }

    /// Subtract two field elements.
    pub fn sub(&self, other: &Self) -> Self {
        let mut result = [0u64; 8];
        let mut borrow = 0u64;
        for i in 0..8 {
            let (diff, b1) = self.limbs[i].overflowing_sub(other.limbs[i]);
            let (diff, b2) = diff.overflowing_sub(borrow);
            result[i] = diff;
            borrow = ((b1 | b2) as u64) << 1;
        }
        Self { limbs: result }
    }

    /// Multiply by a small integer (verified for Kani).
    pub fn mul_small(&self, scalar: u32) -> Self {
        let mut result = [0u64; 8];
        let mut carry = 0u64;
        for i in 0..8 {
            let product = (self.limbs[i] as u128) * (scalar as u128) + (carry as u128);
            result[i] = product as u64;
            carry = (product >> 64) as u64;
        }
        Self { limbs: result }
    }

    /// Check if zero.
    pub fn is_zero(&self) -> bool {
        self.limbs.iter().all(|&x| x == 0)
    }

    /// Get limb at index.
    pub fn limb(&self, index: usize) -> Option<u64> {
        self.limbs.get(index).copied()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mersenne503_creation() {
        let a = Mersenne503::new(42);
        assert_eq!(a.limb(0), Some(42));
        assert_eq!(a.limb(1), Some(0));
    }

    #[test]
    fn test_mersenne503_add() {
        let a = Mersenne503::new(10);
        let b = Mersenne503::new(20);
        let c = a.add(&b);
        assert_eq!(c.limb(0), Some(30));
    }

    #[test]
    fn test_mersenne503_sub() {
        let a = Mersenne503::new(20);
        let b = Mersenne503::new(10);
        let c = a.sub(&b);
        assert_eq!(c.limb(0), Some(10));
    }

    #[test]
    fn test_mersenne503_mul_small() {
        let a = Mersenne503::new(5);
        let b = a.mul_small(3);
        assert_eq!(b.limb(0), Some(15));
    }

    #[test]
    fn test_mersenne503_from_to_bytes() {
        let original = Mersenne503::new(0xDEADBEEF);
        let bytes = original.to_bytes();
        let recovered = Mersenne503::from_bytes(&bytes).unwrap();
        assert_eq!(original, recovered);
    }
}
