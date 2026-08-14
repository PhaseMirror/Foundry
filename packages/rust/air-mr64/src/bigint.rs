use core::cmp::Ordering;

use num_bigint::BigUint;
use num_integer::Integer;
use num_traits::{ToPrimitive, Zero};

/// Number of bits in each limb. We keep the host representation in 32-bit
/// chunks so that the prover/AIR wiring can range-check against the same
/// lookup tables.
pub const LIMB_BITS: usize = 32;
pub const LIMB_BASE: u64 = 1u64 << LIMB_BITS;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct BigInt {
    /// Limbs in little-endian order (least-significant limb first).
    limbs: Vec<u32>,
}

impl BigInt {
    pub fn zero() -> Self {
        Self { limbs: vec![] }
    }

    pub fn one() -> Self {
        Self { limbs: vec![1] }
    }

    pub fn from_u64(value: u64) -> Self {
        if value == 0 {
            return Self::zero();
        }

        let mut limbs = Vec::with_capacity(2);
        limbs.push((value & 0xffff_ffff) as u32);
        let hi = (value >> LIMB_BITS) as u32;
        if hi > 0 {
            limbs.push(hi);
        }
        Self { limbs }
    }

    pub fn from_biguint(value: BigUint) -> Self {
        if value.is_zero() {
            return Self::zero();
        }
        let mut limbs = Vec::new();
        let mut remaining = value;
        let mask = BigUint::from(LIMB_BASE - 1);
        while !remaining.is_zero() {
            let limb = (&remaining & &mask).to_u64().unwrap() as u32;
            limbs.push(limb);
            remaining >>= LIMB_BITS;
        }
        let mut bigint = Self { limbs };
        bigint.normalize();
        bigint
    }

    pub fn to_biguint(&self) -> BigUint {
        if self.limbs.is_empty() {
            return BigUint::zero();
        }
        let mut acc = BigUint::zero();
        for &limb in self.limbs.iter().rev() {
            acc <<= LIMB_BITS;
            acc += BigUint::from(limb);
        }
        acc
    }

    pub fn to_u64(&self) -> Option<u64> {
        match self.limbs.len() {
            0 => Some(0),
            1 => Some(self.limbs[0] as u64),
            2 => Some(self.limbs[0] as u64 | ((self.limbs[1] as u64) << 32)),
            _ => None,
        }
    }

    pub fn is_zero(&self) -> bool {
        self.limbs.is_empty()
    }

    pub fn is_one(&self) -> bool {
        self.limbs.len() == 1 && self.limbs[0] == 1
    }

    pub fn len(&self) -> usize {
        self.limbs.len()
    }

    pub fn cmp(&self, other: &Self) -> Ordering {
        let lhs_len = self.limbs.len();
        let rhs_len = other.limbs.len();
        if lhs_len != rhs_len {
            return lhs_len.cmp(&rhs_len);
        }
        for (a, b) in self.limbs.iter().rev().zip(other.limbs.iter().rev()) {
            if a != b {
                return a.cmp(b);
            }
        }
        Ordering::Equal
    }

    pub fn add(&self, other: &Self) -> Self {
        let mut result = Vec::with_capacity(self.limbs.len().max(other.limbs.len()) + 1);
        let mut carry: u64 = 0;
        for i in 0..self.limbs.len().max(other.limbs.len()) {
            let a = self.limbs.get(i).copied().unwrap_or(0) as u64;
            let b = other.limbs.get(i).copied().unwrap_or(0) as u64;
            let sum = a + b + carry;
            result.push((sum & (LIMB_BASE - 1)) as u32);
            carry = sum >> LIMB_BITS;
        }
        if carry > 0 {
            result.push(carry as u32);
        }
        let mut bigint = Self { limbs: result };
        bigint.normalize();
        bigint
    }

    pub fn sub(&self, other: &Self) -> Self {
        assert!(
            self.cmp(other) != Ordering::Less,
            "negative result in BigInt::sub"
        );
        let mut result = self.limbs.clone();
        let mut borrow: u64 = 0;
        for i in 0..result.len() {
            let a = result[i] as u64;
            let b = other.limbs.get(i).copied().unwrap_or(0) as u64;
            let tmp = LIMB_BASE + a - b - borrow;
            result[i] = (tmp & (LIMB_BASE - 1)) as u32;
            borrow = if tmp < LIMB_BASE { 1 } else { 0 };
        }
        debug_assert!(borrow == 0, "borrow should be zero after subtraction");
        let mut bigint = Self { limbs: result };
        bigint.normalize();
        bigint
    }

    pub fn mul(&self, other: &Self) -> Self {
        if self.is_zero() || other.is_zero() {
            return Self::zero();
        }

        let mut result = vec![0u64; self.len() + other.len()];
        for (i, &a) in self.limbs.iter().enumerate() {
            let mut carry: u64 = 0;
            for (j, &b) in other.limbs.iter().enumerate() {
                let idx = i + j;
                let sum = result[idx] + (a as u64) * (b as u64) + carry;
                result[idx] = sum & (LIMB_BASE - 1);
                carry = sum >> LIMB_BITS;
            }
            let mut idx = i + other.len();
            while carry > 0 {
                if idx >= result.len() {
                    result.push(0);
                }
                let sum = result[idx] + carry;
                result[idx] = sum & (LIMB_BASE - 1);
                carry = sum >> LIMB_BITS;
                idx += 1;
            }
        }

        let mut limbs: Vec<u32> = result.iter().map(|&x| x as u32).collect();
        let mut bigint = Self {
            limbs: limbs.drain(..).collect(),
        };
        bigint.normalize();
        bigint
    }

    pub fn pow_u(&self, mut exp: u32) -> Self {
        let mut base = self.clone();
        let mut acc = Self::one();
        while exp > 0 {
            if exp & 1 == 1 {
                acc = acc.mul(&base);
            }
            exp >>= 1;
            if exp > 0 {
                base = base.mul(&base);
            }
        }
        acc
    }

    pub fn bit_length(&self) -> usize {
        if self.is_zero() {
            return 0;
        }
        let ms = self.limbs.last().copied().unwrap() as u64;
        let ms_bits = 64 - ms.leading_zeros() as usize;
        (self.limbs.len() - 1) * LIMB_BITS + ms_bits
    }

    pub fn is_odd(&self) -> bool {
        !self.limbs.is_empty() && (self.limbs[0] & 1) == 1
    }

    pub fn shr1(&mut self) {
        let mut carry = 0u32;
        for limb in self.limbs.iter_mut().rev() {
            let new_carry = *limb & 1;
            *limb = (*limb >> 1) | (carry << 31);
            carry = new_carry;
        }
        self.normalize();
    }

    pub fn div_rem(&self, other: &Self) -> (Self, Self) {
        assert!(!other.is_zero(), "division by zero");
        if self.cmp(other) == Ordering::Less {
            return (Self::zero(), self.clone());
        }
        let dividend = self.to_biguint();
        let divisor = other.to_biguint();
        let (q, r) = dividend.div_rem(&divisor);
        (Self::from_biguint(q), Self::from_biguint(r))
    }

    pub fn div_exact(&self, other: &Self) -> Option<Self> {
        let (q, r) = self.div_rem(other);
        if !r.is_zero() {
            return None;
        }
        Some(q)
    }

    pub fn trim(&self, digits: usize) -> Self {
        if self.limbs.len() <= digits {
            return self.clone();
        }
        let limbs = self.limbs[..digits].to_vec();
        let mut bigint = Self { limbs };
        bigint.normalize();
        bigint
    }

    pub fn slice_from(&self, start: usize) -> Self {
        if start >= self.limbs.len() {
            return Self::zero();
        }
        let limbs = self.limbs[start..].to_vec();
        let mut bigint = Self { limbs };
        bigint.normalize();
        bigint
    }

    pub fn add_assign(&mut self, other: &Self) {
        let mut carry: u64 = 0;
        let mut i = 0;
        while i < self.limbs.len() || i < other.limbs.len() || carry > 0 {
            if i >= self.limbs.len() {
                self.limbs.push(0);
            }
            let a = self.limbs[i] as u64;
            let b = other.limbs.get(i).copied().unwrap_or(0) as u64;
            let sum = a + b + carry;
            self.limbs[i] = (sum & (LIMB_BASE - 1)) as u32;
            carry = sum >> LIMB_BITS;
            i += 1;
        }
        self.normalize();
    }

    pub fn sub_assign(&mut self, other: &Self) {
        assert!(
            self.cmp(other) != Ordering::Less,
            "negative result in sub_assign"
        );
        let mut borrow: u64 = 0;
        for i in 0..self.limbs.len() {
            let a = self.limbs[i] as u64;
            let b = other.limbs.get(i).copied().unwrap_or(0) as u64;
            let tmp = LIMB_BASE + a - b - borrow;
            self.limbs[i] = (tmp & (LIMB_BASE - 1)) as u32;
            borrow = if tmp < LIMB_BASE { 1 } else { 0 };
        }
        debug_assert!(borrow == 0, "borrow must be zero after sub_assign");
        self.normalize();
    }

    pub fn to_hex(&self) -> String {
        if self.is_zero() {
            return String::from("0x0");
        }
        format!("0x{}", hex::encode(self.to_bytes_be()))
    }

    pub fn to_bytes_be(&self) -> Vec<u8> {
        if self.is_zero() {
            return vec![0];
        }
        let mut bytes = Vec::new();
        for &limb in self.limbs.iter().rev() {
            bytes.extend_from_slice(&limb.to_be_bytes());
        }
        while bytes.first() == Some(&0) {
            bytes.remove(0);
        }
        bytes
    }

    pub fn from_hex(s: &str) -> Option<Self> {
        let s = s.trim();
        let hex_str = s.strip_prefix("0x").unwrap_or(s);
        if hex_str.is_empty() {
            return None;
        }
        let bytes = hex::decode(hex_str).ok()?;
        Some(Self::from_bytes_be(&bytes))
    }

    pub fn from_decimal_str(s: &str) -> Option<Self> {
        let trimmed = s.trim();
        if trimmed.is_empty() {
            return None;
        }
        let value = BigUint::parse_bytes(trimmed.as_bytes(), 10)?;
        Some(Self::from_biguint(value))
    }

    pub fn from_bytes_be(bytes: &[u8]) -> Self {
        if bytes.is_empty() {
            return Self::zero();
        }
        let mut limbs = Vec::with_capacity((bytes.len() + 3) / 4);
        let mut chunk = Vec::new();
        for byte in bytes.iter().rev() {
            chunk.push(*byte);
            if chunk.len() == 4 {
                chunk.reverse();
                let mut array = [0u8; 4];
                array.copy_from_slice(&chunk);
                limbs.push(u32::from_be_bytes(array));
                chunk.clear();
            }
        }
        if !chunk.is_empty() {
            chunk.reverse();
            let mut array = [0u8; 4];
            for (i, byte) in chunk.iter().enumerate() {
                array[4 - chunk.len() + i] = *byte;
            }
            limbs.push(u32::from_be_bytes(array));
        }
        let mut bigint = Self {
            limbs: limbs.into_iter().rev().collect(),
        };
        bigint.normalize();
        bigint
    }

    pub fn normalize(&mut self) {
        while let Some(&last) = self.limbs.last() {
            if last == 0 {
                self.limbs.pop();
            } else {
                break;
            }
        }
    }
}

impl Default for BigInt {
    fn default() -> Self {
        Self::zero()
    }
}

pub struct Modulus {
    pub p: BigInt,
    mu: BigInt,
    k: usize,
}

impl Modulus {
    pub fn new(p: BigInt) -> Self {
        assert!(!p.is_zero(), "modulus must be non-zero");
        let k = p.len();
        let mut b_pow_limbs = vec![0u32; 2 * k];
        b_pow_limbs.push(1);
        let b_pow = BigInt { limbs: b_pow_limbs };
        let mu = b_pow.div_rem(&p).0;
        Self { p, mu, k }
    }

    pub fn mul_red(&self, a: &BigInt, b: &BigInt) -> BigInt {
        let t = a.mul(b);
        self.reduce_internal(&t)
    }

    pub fn add_red(&self, a: &BigInt, b: &BigInt) -> BigInt {
        let mut sum = a.add(b);
        if sum.cmp(&self.p) != Ordering::Less {
            sum.sub_assign(&self.p);
        }
        sum
    }

    pub fn pow_mod(&self, base: &BigInt, exp: &BigInt) -> BigInt {
        if exp.is_zero() {
            return BigInt::one();
        }
        let mut result = BigInt::one();
        let mut base_acc = self.reduce_internal(base);
        let mut e = exp.clone();
        while !e.is_zero() {
            if e.is_odd() {
                result = self.mul_red(&result, &base_acc);
            }
            e.shr1();
            if !e.is_zero() {
                base_acc = self.mul_red(&base_acc, &base_acc);
            }
        }
        result
    }

    fn reduce_internal(&self, value: &BigInt) -> BigInt {
        if value.cmp(&self.p) == Ordering::Less {
            return value.clone();
        }

        let k = self.k;
        let q1 = value.slice_from(k.saturating_sub(1));
        let q2 = q1.mul(&self.mu);
        let q3 = q2.slice_from(k + 1);

        let r1 = value.trim(k + 1);
        let r2_full = q3.mul(&self.p);
        let r2 = r2_full.trim(k + 1);

        let mut r = if r1.cmp(&r2) != Ordering::Less {
            r1.sub(&r2)
        } else {
            let mut correction_limbs = vec![0u32; k + 1];
            correction_limbs.push(1);
            let correction = BigInt {
                limbs: correction_limbs,
            };
            let mut tmp = r1.add(&correction);
            tmp.sub_assign(&r2);
            tmp
        };

        while r.cmp(&self.p) != Ordering::Less {
            r.sub_assign(&self.p);
        }

        r
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn add_and_mul_roundtrip() {
        let a = BigInt::from_decimal_str("12345678901234567890").unwrap();
        let b = BigInt::from_decimal_str("98765432109876543210").unwrap();
        let sum = a.add(&b);
        assert_eq!(sum.to_biguint().to_string(), "111111111011111111100");

        let product = a.mul(&b);
        assert_eq!(
            product.to_biguint().to_string(),
            "1219326311370217952237463801111263526900"
        );
    }

    #[test]
    fn barrett_mul_matches_mod() {
        let modulus = Modulus::new(BigInt::from_u64(97));
        let a = BigInt::from_u64(1234);
        let b = BigInt::from_u64(9876);
        let reduced = modulus.mul_red(&a, &b);
        assert_eq!(
            reduced.to_u64(),
            Some((1234u128 * 9876u128 % 97u128) as u64)
        );
    }
}
