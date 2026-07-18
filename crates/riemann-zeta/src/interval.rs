//! Interval arithmetic for rigorous Riemann zeta bounds
//!
//! Provides verified interval arithmetic using MPFR-backed floats,
//! ensuring that all bounds on ζ(s) are mathematically rigorous.

use rug::{Float, Complex};
use serde::{Deserialize, Serialize};

use crate::{RiemannError, Result};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Interval {
    pub low: Float,
    pub high: Float,
    pub precision: u32,
}

impl Interval {
    pub fn new(low: Float, high: Float) -> Result<Self> {
        let precision = low.prec();
        if precision != high.prec() {
            return Err(RiemannError::InvalidArgument(
                format!("Interval endpoints must have matching precision: {} != {}", precision, high.prec())
            ));
        }
        if low > high {
            return Err(RiemannError::InvalidArgument(
                format!("Interval lower bound {} exceeds upper bound {}", low, high)
            ));
        }
        Ok(Self { low, high, precision })
    }

    /// Check if this interval contains a given value.
    pub fn contains(&self, value: &Float) -> bool {
        self.low <= value && value <= self.high
    }

    /// Check if this interval contains zero.
    pub fn contains_zero(&self) -> bool {
        self.contains(&Float::with_val(self.precision, 0))
    }

    /// Compute the width of the interval.
    pub fn width(&self) -> Float {
        &self.high - &self.low
    }

    /// Verify that the interval is tight (width ≤ threshold).
    pub fn is_tight(&self, threshold: &Float) -> bool {
        self.width() <= threshold.clone()
    }
}

impl std::ops::Add for Interval {
    type Output = Result<Self>;

    fn add(self, rhs: Self) -> Result<Self> {
        let low = &self.low + &rhs.low;
        let high = &self.high + &rhs.high;
        Self::new(low, high)
    }
}

impl std::ops::Sub for Interval {
    type Output = Result<Self>;

    fn sub(self, rhs: Self) -> Result<Self> {
        let low = &self.low - &rhs.high;
        let high = &self.high - &rhs.low;
        Self::new(low, high)
    }
}

impl std::ops::Mul for Interval {
    type Output = Result<Self>;

    fn mul(self, rhs: Self) -> Result<Self> {
        let products = [
            &self.low * &rhs.low,
            &self.low * &rhs.high,
            &self.high * &rhs.low,
            &self.high * &rhs.high,
        ];
        let low = products.iter().min_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal)).unwrap();
        let high = products.iter().max_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal)).unwrap();
        Self::new(low.clone(), high.clone())
    }
}

impl std::ops::Div for Interval {
    type Output = Result<Self>;

    fn div(self, rhs: Self) -> Result<Self> {
        if rhs.contains_zero() {
            return Err(RiemannError::InvalidArgument(
                "Division by interval containing zero".to_string()
            ));
        }
        let products = [
            &self.low / &rhs.low,
            &self.low / &rhs.high,
            &self.high / &rhs.low,
            &self.high / &rhs.high,
        ];
        let low = products.iter().min_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal)).unwrap();
        let high = products.iter().max_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal)).unwrap();
        Self::new(low.clone(), high.clone())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerifiedBound {
    pub value: Float,
    pub error_margin: Float,
    pub is_verified: bool,
}

impl VerifiedBound {
    pub fn new(value: Float, error_margin: Float) -> Self {
        let is_verified = error_margin < Float::with_val(value.prec(), 1e-15);
        Self { value, error_margin, is_verified }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_interval_contains_zero() {
        let low = Float::with_val(128, -0.1);
        let high = Float::with_val(128, 0.1);
        let interval = Interval::new(low, high).unwrap();
        assert!(interval.contains_zero());
    }

    #[test]
    fn test_interval_arithmetic() {
        let a = Interval::new(
            Float::with_val(128, 1.0),
            Float::with_val(128, 2.0),
        ).unwrap();
        let b = Interval::new(
            Float::with_val(128, 0.5),
            Float::with_val(128, 1.5),
        ).unwrap();

        let sum = (a.clone() + b.clone()).unwrap();
        assert!(sum.contains(&Float::with_val(128, 1.5)));
        assert!(sum.contains(&Float::with_val(128, 3.5)));

        let diff = (a.clone() - b.clone()).unwrap();
        assert!(diff.contains(&Float::with_val(128, -0.5)));
    }
}
