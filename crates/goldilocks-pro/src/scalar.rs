use crate::MODULUS;
use std::ops::{Add, Sub, Mul, Neg};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct GoldilocksField(pub u64);

impl GoldilocksField {
    pub const ZERO: Self = Self(0);
    pub const ONE: Self = Self(1);

    pub fn new(val: u64) -> Self {
        Self(val % MODULUS)
    }

    /// Canonicalize the value to be in [0, MODULUS).
    pub fn canonicalize(self) -> Self {
        Self(self.0 % MODULUS)
    }

    pub fn inv(self) -> Self {
        if self.0 == 0 {
            panic!("Division by zero");
        }
        // Fermat's Little Theorem: a^(p-2) % p
        self.pow(MODULUS - 2)
    }

    pub fn pow(self, mut exp: u64) -> Self {
        let mut res = Self::ONE;
        let mut base = self;
        while exp > 0 {
            if exp % 2 == 1 {
                res = res * base;
            }
            base = base * base;
            exp /= 2;
        }
        res
    }
}

impl Add for GoldilocksField {
    type Output = Self;
    fn add(self, rhs: Self) -> Self {
        let (sum, overflow) = self.0.overflowing_add(rhs.0);
        if overflow {
            // sum = (a + b) % 2^64
            // (a + b) = 2^64 + sum \equiv sum + 2^32 - 1 (mod p)
            Self(sum.wrapping_add(0x0000_0000_FFFF_FFFF))
        } else if sum >= MODULUS {
            Self(sum - MODULUS)
        } else {
            Self(sum)
        }
    }
}

impl Sub for GoldilocksField {
    type Output = Self;
    fn sub(self, rhs: Self) -> Self {
        let (res, borrow) = self.0.overflowing_sub(rhs.0);
        if borrow {
            // res = (a - b) % 2^64
            // (a - b) = res - 2^64 \equiv res - (2^32 - 1) (mod p)
            Self(res.wrapping_sub(0x0000_0000_FFFF_FFFF))
        } else {
            Self(res)
        }
    }
}

impl Neg for GoldilocksField {
    type Output = Self;
    fn neg(self) -> Self {
        if self.0 == 0 {
            self
        } else {
            Self(MODULUS - self.0)
        }
    }
}

impl Mul for GoldilocksField {
    type Output = Self;
    fn mul(self, rhs: Self) -> Self {
        let prod = (self.0 as u128) * (rhs.0 as u128);
        let lo = prod as u64;
        let hi = (prod >> 64) as u64;

        // x = hi * 2^64 + lo
        // x \equiv lo + hi_lo * 2^32 - hi_hi - hi_lo (mod p)
        let hi_lo = hi & 0xFFFF_FFFF;
        let hi_hi = hi >> 32;

        let (res, borrow) = lo.overflowing_add(hi_lo << 32);
        let mut res = if borrow {
            res.wrapping_add(0x0000_0000_FFFF_FFFF)
        } else {
            res
        };

        let (res_final, borrow) = res.overflowing_sub(hi_hi + hi_lo);
        if borrow {
            res = res_final.wrapping_add(MODULUS);
        } else {
            res = res_final;
        }

        Self(res).canonicalize()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    #[test]
    fn test_add() {
        let a = GoldilocksField::new(MODULUS - 1);
        let b = GoldilocksField::new(1);
        assert_eq!(a + b, GoldilocksField::ZERO);
    }

    #[test]
    fn test_sub() {
        let a = GoldilocksField::ZERO;
        let b = GoldilocksField::new(1);
        assert_eq!(a - b, GoldilocksField::new(MODULUS - 1));
    }

    #[test]
    fn test_mul() {
        let a = GoldilocksField::new(1 << 32);
        let b = GoldilocksField::new(1 << 32);
        // (2^32)^2 = 2^64 \equiv 2^32 - 1 (mod p)
        assert_eq!(a * b, GoldilocksField::new((1 << 32) - 1));
    }

    proptest! {
        #[test]
        fn test_add_proptest(a in 0..MODULUS, b in 0..MODULUS) {
            let fa = GoldilocksField(a);
            let fb = GoldilocksField(b);
            let expected = ((a as u128 + b as u128) % MODULUS as u128) as u64;
            assert_eq!((fa + fb).0, expected);
        }

        #[test]
        fn test_sub_proptest(a in 0..MODULUS, b in 0..MODULUS) {
            let fa = GoldilocksField(a);
            let fb = GoldilocksField(b);
            let expected = if a >= b { a - b } else { MODULUS - (b - a) };
            assert_eq!((fa - fb).0, expected);
        }

        #[test]
        fn test_mul_proptest(a in 0..MODULUS, b in 0..MODULUS) {
            let fa = GoldilocksField(a);
            let fb = GoldilocksField(b);
            let expected = ((a as u128 * b as u128) % MODULUS as u128) as u64;
            assert_eq!((fa * fb).0, expected);
        }
        
        #[test]
        fn test_inv_proptest(a in 1..MODULUS) {
            let fa = GoldilocksField(a);
            let inv_a = fa.inv();
            assert_eq!((fa * inv_a).0, 1);
        }
    }
}
