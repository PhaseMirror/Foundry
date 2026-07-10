/// Goldilocks field: p = 2^64 - 2^32 + 1
/// 
/// This is a 64-bit prime field optimized for STARK proofs.
/// Operations are performed modulo GOLDILOCKS_PRIME.

pub mod polynomial;
#[cfg(target_arch = "x86_64")]
pub mod sse;
#[cfg(target_arch = "x86_64")]
pub mod avx2;

use serde::{Deserialize, Serialize};

/// Goldilocks prime: 2^64 - 2^32 + 1 = 18446744069414584321
pub const GOLDILOCKS_PRIME: u64 = 0xFFFFFFFF00000001;

/// The first 64 prime numbers used for prime-gated indexing (P_64).
pub const P_64: [u64; 64] = [
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 
    73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 
    157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 
    239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311,
];

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct GoldilocksField(u64);

impl GoldilocksField {
    pub const ZERO: Self = Self(0);
    pub const ONE: Self = Self(1);

    #[inline]
    pub fn new(value: u64) -> Self {
        Self(value % GOLDILOCKS_PRIME)
    }

    #[inline]
    pub fn from_canonical(value: u64) -> Self {
        debug_assert!(value < GOLDILOCKS_PRIME);
        Self(value)
    }

    #[inline]
    pub fn to_canonical(&self) -> u64 {
        self.0
    }
    
    // ... rest of implementation (add, sub, mul, etc. are below)
}

/// A 64-bit prime mask where bit k is set if the k-th prime in P_64 is attached.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct PrimeMask(pub u64);

impl PrimeMask {
    pub const EMPTY: Self = Self(0);

    #[inline]
    pub fn and(&self, other: &Self) -> Self {
        Self(self.0 & other.0)
    }

    #[inline]
    pub fn or(&self, other: &Self) -> Self {
        Self(self.0 | other.0)
    }

    #[inline]
    pub fn xor(&self, other: &Self) -> Self {
        Self(self.0 ^ other.0)
    }

    #[inline]
    pub fn is_prime_set(&self, k: usize) -> bool {
        if k >= 64 { return false; }
        (self.0 & (1 << k)) != 0
    }

    #[inline]
    pub fn to_field(&self) -> GoldilocksField {
        GoldilocksField::from_canonical(self.0)
    }
}

/// A 64-bit resonance word: bits 0-6 = class (0-95), bits 7-63 = 57-bit payload.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct ResonanceWord(pub u64);

impl ResonanceWord {
    pub const NEUTRAL: Self = Self(0);

    pub fn pack(class: u8, payload: u64) -> Self {
        assert!(class < 96, "Resonance class must be < 96");
        assert!(payload < (1 << 57), "Payload must fit in 57 bits");
        Self((payload << 7) | (class as u64))
    }

    pub fn unpack(&self) -> (u8, u64) {
        let class = (self.0 & 0x7F) as u8;
        let payload = self.0 >> 7;
        (class, payload)
    }

    #[inline]
    pub fn to_field(&self) -> GoldilocksField {
        GoldilocksField::from_canonical(self.0)
    }
}

/// Witness for primality of mask components.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeWitness {
    pub mask: PrimeMask,
    pub witnesses: std::collections::HashMap<u8, PrimeVerificationLog>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeVerificationLog {
    pub miller_rabin_log: Vec<u64>,
    pub trial_div_log: Vec<u8>,
    pub seed: u64,
}

impl GoldilocksField {

    /// Add two field elements
    #[inline]
    pub fn add(&self, rhs: &Self) -> Self {
        let sum = self.0 as u128 + rhs.0 as u128;
        Self(reduce128(sum))
    }

    /// Subtract two field elements
    #[inline]
    pub fn sub(&self, rhs: &Self) -> Self {
        if self.0 >= rhs.0 {
            Self(self.0 - rhs.0)
        } else {
            Self(GOLDILOCKS_PRIME - (rhs.0 - self.0))
        }
    }

    /// Multiply two field elements
    #[inline]
    pub fn mul(&self, rhs: &Self) -> Self {
        let prod = self.0 as u128 * rhs.0 as u128;
        Self(reduce128(prod))
    }

    /// Negate a field element
    #[inline]
    pub fn neg(&self) -> Self {
        if self.0 == 0 {
            Self::ZERO
        } else {
            Self(GOLDILOCKS_PRIME - self.0)
        }
    }

    /// Compute multiplicative inverse using Fermat's little theorem
    /// a^(p-1) = 1 (mod p) => a^(p-2) = a^(-1) (mod p)
    pub fn inverse(&self) -> Option<Self> {
        if self.0 == 0 {
            return None;
        }
        Some(self.pow(GOLDILOCKS_PRIME - 2))
    }

    /// Exponentiation by squaring
    pub fn pow(&self, mut exp: u64) -> Self {
        let mut result = Self::ONE;
        let mut base = *self;
        
        while exp > 0 {
            if exp & 1 == 1 {
                result = result.mul(&base);
            }
            base = base.mul(&base);
            exp >>= 1;
        }
        
        result
    }
}

/// Reduce a 128-bit value modulo Goldilocks prime
/// Uses the fact that p = 2^64 - 2^32 + 1
#[inline]
fn reduce128(x: u128) -> u64 {
    let lo = x as u64;
    let hi = (x >> 64) as u64;
    
    // x = hi * 2^64 + lo
    // Since 2^64 ≡ 2^32 - 1 (mod p), we have:
    // x mod p = hi * (2^32 - 1) + lo mod p
    let mut reduced = lo as u128 + hi as u128 * 0xFFFFFFFF;
    
    // May still need one more reduction
    while reduced >= GOLDILOCKS_PRIME as u128 {
        reduced -= GOLDILOCKS_PRIME as u128;
    }
    
    reduced as u64
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        let a = GoldilocksField::new(5);
        let b = GoldilocksField::new(10);
        assert_eq!(a.add(&b), GoldilocksField::new(15));
    }

    #[test]
    fn test_mul() {
        let a = GoldilocksField::new(7);
        let b = GoldilocksField::new(11);
        assert_eq!(a.mul(&b), GoldilocksField::new(77));
    }

    #[test]
    fn test_inverse() {
        let a = GoldilocksField::new(7);
        let inv = a.inverse().unwrap();
        assert_eq!(a.mul(&inv), GoldilocksField::ONE);
    }
}
