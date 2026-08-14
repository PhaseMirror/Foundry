#[cfg(target_arch = "x86_64")]
pub mod avx2;
/// Goldilocks field: p = 2^64 - 2^32 + 1
///
/// This is a 64-bit prime field optimized for STARK proofs.
/// Operations are performed modulo GOLDILOCKS_PRIME.
pub mod polynomial;
#[cfg(target_arch = "x86_64")]
pub mod sse;

use serde::{Deserialize, Serialize};

/// Goldilocks prime: 2^64 - 2^32 + 1 = 18446744069414584321
pub const GOLDILOCKS_PRIME: u64 = 0xFFFFFFFF00000001;

/// Canonical fixed-point scaling factor for Goldilocks field arithmetic.
/// Used to convert floating-point values to u64 for field operations.
pub const SCALE_GOLDILOCKS: u64 = 1 << 40;

/// The first 64 prime numbers used for prime-gated indexing (P_64).
pub const P_64: [u64; 64] = [
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97,
    101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193,
    197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307,
    311,
];

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct GoldilocksField(pub u64);

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
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
pub struct PrimeMask(pub u64);

impl PrimeMask {
    pub const EMPTY: Self = Self(0);

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

    /// Alias for `is_set` with `usize` argument for backward compatibility.
    #[inline]
    pub fn is_prime_set(&self, k: usize) -> bool {
        if k >= 64 {
            return false;
        }
        (self.0 & (1 << k)) != 0
    }

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
    pub fn count_ones(&self) -> u32 {
        self.0.count_ones()
    }

    #[inline]
    pub fn to_field(&self) -> GoldilocksField {
        GoldilocksField::from_canonical(self.0)
    }
}

/// A 64-bit resonance word: bits 0-6 = class (0-127), bits 7-63 = 57-bit payload.
///
/// NOTE: Some downstream crates (goldilocks-pro, c-pirtm, core, pirtm-candle) historically
/// used a 6-bit class / 58-bit payload layout. The 7-bit layout here is the canonical
/// version that can represent all 96 R96 resonance classes.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
pub struct ResonanceWord(pub u64);

impl ResonanceWord {
    pub const NEUTRAL: Self = Self(0);
    pub const Q29_29_SHIFT: u64 = 1 << 29;

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

    /// Pack a floating point value into a Q29.29 fixed-point payload.
    #[inline]
    pub fn pack_q29_29(class: u8, val: f64) -> Self {
        let payload = (val * (Self::Q29_29_SHIFT as f64)).round() as i64;
        let payload = payload.clamp(-(1 << 56), (1 << 56) - 1);
        let u_payload = (payload as u64) & ((1 << 57) - 1);
        Self::pack(class, u_payload)
    }

    /// Unpack a Q29.29 fixed-point payload into a floating point value.
    #[inline]
    pub fn unpack_q29_29(&self) -> (u8, f64) {
        let (c, payload) = self.unpack();
        let mut val = payload;
        if (val & (1 << 56)) != 0 {
            val |= !((1 << 57) - 1);
        }
        let fval = (val as i64) as f64 / (Self::Q29_29_SHIFT as f64);
        (c, fval)
    }

    #[inline]
    pub fn class(&self) -> u8 {
        (self.0 & 0x7F) as u8
    }

    #[inline]
    pub fn payload(&self) -> u64 {
        self.0 >> 7
    }

    #[inline]
    pub fn to_field(&self) -> GoldilocksField {
        GoldilocksField::from_canonical(self.0)
    }
}

/// An atomic prime number stored as a u64.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct AtomicPrime(pub u64);

/// A PIRTM modulus value.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PirtmModulus(pub u64);

impl PirtmModulus {
    pub fn value(&self) -> u64 {
        self.0
    }
}

/// A squarefree composite number (product of distinct primes).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SquarefreeComposite(pub u64);

impl SquarefreeComposite {
    pub fn new(n: u64) -> Result<Self, String> {
        let mut temp = n;
        let mut p = 2u64;
        while p * p <= temp {
            if temp % p == 0 {
                temp /= p;
                if temp % p == 0 {
                    return Err(format!("{} is not squarefree (divisible by {}^2)", n, p));
                }
            }
            p += 1;
        }
        Ok(Self(n))
    }
}

/// Witness for primality of mask components.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeWitness {
    pub mask: PrimeMask,
    pub witnesses: std::collections::HashMap<u8, PrimeVerificationLog>,
}

/// Witness for Goldilocks field operations.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GoldilocksWitness {
    /// Operation name: "add", "sub", "mul", "inv".
    pub op: String,
    /// Left‑hand operand (canonical value).
    pub lhs: u64,
    /// Right‑hand operand (canonical). `None` for unary ops like `inv`.
    pub rhs: Option<u64>,
    /// Resulting field element (canonical).
    pub result: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeVerificationLog {
    pub miller_rabin_log: Vec<u64>,
    pub trial_div_log: Vec<u8>,
    pub seed: u64,
}

impl GoldilocksField {
    // Internal witness storage (process-wide).
    #[cfg(not(test))]
    fn emit_witness(w: GoldilocksWitness) {
        use once_cell::sync::Lazy;
        use std::sync::Mutex;
        static WITNESSES: Lazy<Mutex<Vec<GoldilocksWitness>>> =
            Lazy::new(|| Mutex::new(Vec::new()));
        let _ = WITNESSES.lock().map(|mut v| v.push(w));
    }

    #[cfg(test)]
    fn emit_witness(_w: GoldilocksWitness) {}

    /// Add two field elements, emitting a witness.
    #[inline]
    pub fn add(&self, rhs: &Self) -> Self {
        let sum = self.0 as u128 + rhs.0 as u128;
        let res = Self(reduce128(sum));
        // Emit witness for addition
        Self::emit_witness(GoldilocksWitness {
            op: "add".to_string(),
            lhs: self.0,
            rhs: Some(rhs.0),
            result: res.0,
        });
        res
    }

    /// Subtract two field elements, emitting a witness.
    #[inline]
    pub fn sub(&self, rhs: &Self) -> Self {
        let res = if self.0 >= rhs.0 {
            Self(self.0 - rhs.0)
        } else {
            Self(GOLDILOCKS_PRIME - (rhs.0 - self.0))
        };
        Self::emit_witness(GoldilocksWitness {
            op: "sub".to_string(),
            lhs: self.0,
            rhs: Some(rhs.0),
            result: res.0,
        });
        res
    }

    /// Multiply two field elements, emitting a witness.
    #[inline]
    pub fn mul(&self, rhs: &Self) -> Self {
        let prod = self.0 as u128 * rhs.0 as u128;
        let res = Self(reduce128(prod));
        Self::emit_witness(GoldilocksWitness {
            op: "mul".to_string(),
            lhs: self.0,
            rhs: Some(rhs.0),
            result: res.0,
        });
        res
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
    /// Emits a witness for the inversion.
    pub fn inverse(&self) -> Option<Self> {
        if self.0 == 0 {
            return None;
        }
        let inv = self.pow(GOLDILOCKS_PRIME - 2);
        Self::emit_witness(GoldilocksWitness {
            op: "inv".to_string(),
            lhs: self.0,
            rhs: None,
            result: inv.0,
        });
        Some(inv)
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

impl std::ops::Add for GoldilocksField {
    type Output = Self;
    #[inline]
    fn add(self, rhs: Self) -> Self {
        let sum = self.0 as u128 + rhs.0 as u128;
        Self(reduce128(sum))
    }
}

impl std::ops::Sub for GoldilocksField {
    type Output = Self;
    #[inline]
    fn sub(self, rhs: Self) -> Self {
        if self.0 >= rhs.0 {
            Self(self.0 - rhs.0)
        } else {
            Self(GOLDILOCKS_PRIME - (rhs.0 - self.0))
        }
    }
}

impl std::ops::Mul for GoldilocksField {
    type Output = Self;
    #[inline]
    fn mul(self, rhs: Self) -> Self {
        let prod = self.0 as u128 * rhs.0 as u128;
        Self(reduce128(prod))
    }
}

impl std::ops::Neg for GoldilocksField {
    type Output = Self;
    #[inline]
    fn neg(self) -> Self {
        if self.0 == 0 {
            Self::ZERO
        } else {
            Self(GOLDILOCKS_PRIME - self.0)
        }
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
    // x mod p = hi * (2^32 - 1) + lo (mod p)
    let reduced = lo as u128 + hi as u128 * 0xFFFFFFFF;

    // Reduce modulo p in a single step using the remainder operator.
    (reduced % GOLDILOCKS_PRIME as u128) as u64
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

#[cfg(feature = "kani")]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_add_mod_p() {
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        kani::assume(a < GOLDILOCKS_PRIME && b < GOLDILOCKS_PRIME);
        let fa = GoldilocksField(a);
        let fb = GoldilocksField(b);
        let res = fa.add(&fb);
        kani::assert(res.0 < GOLDILOCKS_PRIME, "Add wrapping");
    }

    #[kani::proof]
    fn proof_sub_mod_p() {
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        kani::assume(a < GOLDILOCKS_PRIME && b < GOLDILOCKS_PRIME);
        let fa = GoldilocksField(a);
        let fb = GoldilocksField(b);
        let res = fa.sub(&fb);
        kani::assert(res.0 < GOLDILOCKS_PRIME, "Sub wrapping");
    }

    #[kani::proof]
    fn proof_mul_mod_p() {
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        kani::assume(a < GOLDILOCKS_PRIME && b < GOLDILOCKS_PRIME);
        let fa = GoldilocksField(a);
        let fb = GoldilocksField(b);
        let res = fa.mul(&fb);
        kani::assert(res.0 < GOLDILOCKS_PRIME, "Mul wrapping");
    }

    #[kani::proof]
    fn proof_inv_mod_p() {
        let a: u64 = kani::any();
        kani::assume(a < GOLDILOCKS_PRIME && a != 0);
        let fa = GoldilocksField(a);
        let inv = fa.inverse().unwrap();
        let prod = fa.mul(&inv);
        // The product should be ONE modulo the prime.
        kani::assert(prod.0 == GoldilocksField::ONE.0, "Inverse correctness");
    }
}
