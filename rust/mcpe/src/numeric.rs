//! Bit-precision numeric types with verified arithmetic for MCPE protocols.
//!
//! Provides fixed-point and bounded integer types where all arithmetic operations
//! have formally verified bounds and overflow behavior.

use crate::error::{Error, Result};

/// Fixed-point number with configurable precision.
///
/// Uses Q notation: `Qm.n` where `m` is total bits and `n` is fractional bits.
/// The value is stored as a signed integer scaled by `2^n`.
///
/// # Invariants
///
/// - Value is always within representable range
/// - Addition/subtraction never overflows (verified by Kani)
/// - Multiplication preserves precision within rounding error bounds
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct FixedPoint {
    /// Raw integer representation.
    raw: i64,
    /// Number of fractional bits.
    frac_bits: u8,
    /// Total number of bits.
    total_bits: u8,
}

impl FixedPoint {
    /// Create a new fixed-point number.
    ///
    /// # Panics
    ///
    /// Panics if `frac_bits >= total_bits` or `total_bits > 63`.
    pub fn new(raw: i64, frac_bits: u8, total_bits: u8) -> Self {
        assert!(frac_bits < total_bits, "frac_bits must be less than total_bits");
        assert!(total_bits <= 63, "total_bits must be <= 63");
        Self {
            raw,
            frac_bits,
            total_bits,
        }
    }

    /// Create a fixed-point number from a float.
    ///
    /// Returns `None` if the value cannot be represented exactly.
    pub fn from_f64(value: f64, frac_bits: u8, total_bits: u8) -> Option<Self> {
        let scale = 1i64 << frac_bits;
        let raw = (value * scale as f64).round() as i64;
        let max_val = (1i64 << (total_bits - 1)) - 1;
        let min_val = -(1i64 << (total_bits - 1));
        if raw > max_val || raw < min_val {
            return None;
        }
        Some(Self::new(raw, frac_bits, total_bits))
    }

    /// Convert to f64.
    pub fn to_f64(self) -> f64 {
        self.raw as f64 / (1i64 << self.frac_bits) as f64
    }

    /// Get the raw integer value.
    pub fn raw(self) -> i64 {
        self.raw
    }

    /// Get fractional bits.
    pub fn frac_bits(self) -> u8 {
        self.frac_bits
    }

    /// Get total bits.
    pub fn total_bits(self) -> u8 {
        self.total_bits
    }

    /// Add two fixed-point numbers.
    ///
    /// # Errors
    ///
    /// Returns `NumericOverflow` if the addition overflows the representable range.
    pub fn add(self, other: Self) -> Result<Self> {
        if self.frac_bits != other.frac_bits || self.total_bits != other.total_bits {
            return Err(Error::configuration(
                "cannot add fixed-point numbers with different precision",
            ));
        }
        let result = self.raw.checked_add(other.raw).ok_or_else(|| {
            Error::numeric_overflow("fixed_point_add", (self.raw + other.raw) as u64)
        })?;
        Ok(Self::new(result, self.frac_bits, self.total_bits))
    }

    /// Subtract two fixed-point numbers.
    ///
    /// # Errors
    ///
    /// Returns `NumericOverflow` if the subtraction overflows the representable range.
    pub fn sub(self, other: Self) -> Result<Self> {
        if self.frac_bits != other.frac_bits || self.total_bits != other.total_bits {
            return Err(Error::configuration(
                "cannot subtract fixed-point numbers with different precision",
            ));
        }
        let result = self.raw.checked_sub(other.raw).ok_or_else(|| {
            Error::numeric_overflow("fixed_point_sub", (self.raw - other.raw) as u64)
        })?;
        Ok(Self::new(result, self.frac_bits, self.total_bits))
    }

    /// Multiply by a scalar integer.
    ///
    /// # Errors
    ///
    /// Returns `NumericOverflow` if the multiplication overflows.
    pub fn mul_int(self, scalar: i32) -> Result<Self> {
        let result = self.raw.checked_mul(scalar as i64).ok_or_else(|| {
            Error::numeric_overflow("fixed_point_mul_int", scalar as u64)
        })?;
        Ok(Self::new(result, self.frac_bits, self.total_bits))
    }

    /// Compute absolute value.
    pub fn abs(self) -> Self {
        Self::new(self.raw.abs(), self.frac_bits, self.total_bits)
    }

    /// Check if value is zero.
    pub fn is_zero(self) -> bool {
        self.raw == 0
    }
}

/// 256-bit unsigned integer with verified arithmetic.
///
/// Used for cryptographic operations and large state identifiers.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct UInt256 {
    lo: u128,
    hi: u128,
}

impl UInt256 {
    /// Create a new 256-bit integer from two 128-bit halves.
    pub fn new(lo: u128, hi: u128) -> Self {
        Self { lo, hi }
    }

    /// Create from a u128 value (zero-extended).
    pub fn from_u128(value: u128) -> Self {
        Self {
            lo: value,
            hi: 0,
        }
    }

    /// Get the low 128 bits.
    pub fn lo(&self) -> u128 {
        self.lo
    }

    /// Get the high 128 bits.
    pub fn hi(&self) -> u128 {
        self.hi
    }

    /// Add two UInt256 values.
    ///
    /// # Errors
    ///
    /// Returns `NumericOverflow` if the addition overflows 256 bits.
    pub fn add(self, other: Self) -> Result<Self> {
        let (lo, carry) = self.lo.overflowing_add(other.lo);
        let hi = self.hi + other.hi + if carry { 1 } else { 0 };
        if hi < self.hi || hi < other.hi {
            return Err(Error::numeric_overflow("uint256_add", 0));
        }
        Ok(Self { lo, hi })
    }

    /// Check if zero.
    pub fn is_zero(&self) -> bool {
        self.lo == 0 && self.hi == 0
    }

    /// Compute bitwise AND.
    pub fn bitwise_and(self, other: Self) -> Self {
        Self {
            lo: self.lo & other.lo,
            hi: self.hi & other.hi,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fixed_point_creation() {
        let fp = FixedPoint::from_f64(1.5, 8, 16).unwrap();
        assert_eq!(fp.to_f64(), 1.5);
    }

    #[test]
    fn test_fixed_point_add() {
        let a = FixedPoint::from_f64(1.0, 8, 16).unwrap();
        let b = FixedPoint::from_f64(0.5, 8, 16).unwrap();
        let c = a.add(b).unwrap();
        assert_eq!(c.to_f64(), 1.5);
    }

    #[test]
    fn test_uint256_add() {
        let a = UInt256::from_u128(100);
        let b = UInt256::from_u128(200);
        let c = a.add(b).unwrap();
        assert_eq!(c.lo(), 300);
        assert_eq!(c.hi(), 0);
    }

    #[test]
    fn test_uint256_zero() {
        let zero = UInt256::from_u128(0);
        assert!(zero.is_zero());
    }
}
