//! Local numeric trait for HRM operations
//!
//! This is a simplified version of the Numeric trait from hologram-onnx,
//! included here because hologram-onnx is temporarily disabled.

use bytemuck::Pod;
use std::fmt::Debug;

/// Trait for numeric types that can be used in ONNX operations
pub trait Numeric: Pod + Debug + Copy + Default + PartialOrd + 'static + Send + Sync {
    /// Zero value for this type
    fn zero() -> Self;

    /// One value for this type
    fn one() -> Self;

    /// Convert from i64
    fn from_i64(value: i64) -> Self;

    /// Convert to i64
    fn to_i64(self) -> i64;

    /// Convert from f32
    fn from_f32(value: f32) -> Self;

    /// Convert to f32
    fn to_f32(self) -> f32;

    /// Add two values
    fn add(self, other: Self) -> Self;

    /// Subtract two values
    fn sub(self, other: Self) -> Self;

    /// Multiply two values
    fn mul(self, other: Self) -> Self;

    /// Divide two values
    fn div(self, other: Self) -> Self;
}

// Float32 Implementation
impl Numeric for f32 {
    #[inline]
    fn zero() -> Self {
        0.0
    }

    #[inline]
    fn one() -> Self {
        1.0
    }

    #[inline]
    fn from_i64(value: i64) -> Self {
        value as f32
    }

    #[inline]
    fn to_i64(self) -> i64 {
        self as i64
    }

    #[inline]
    fn from_f32(value: f32) -> Self {
        value
    }

    #[inline]
    fn to_f32(self) -> f32 {
        self
    }

    #[inline]
    fn add(self, other: Self) -> Self {
        self + other
    }

    #[inline]
    fn sub(self, other: Self) -> Self {
        self - other
    }

    #[inline]
    fn mul(self, other: Self) -> Self {
        self * other
    }

    #[inline]
    fn div(self, other: Self) -> Self {
        self / other
    }
}

// Float64 Implementation
impl Numeric for f64 {
    #[inline]
    fn zero() -> Self {
        0.0
    }

    #[inline]
    fn one() -> Self {
        1.0
    }

    #[inline]
    fn from_i64(value: i64) -> Self {
        value as f64
    }

    #[inline]
    fn to_i64(self) -> i64 {
        self as i64
    }

    #[inline]
    fn from_f32(value: f32) -> Self {
        value as f64
    }

    #[inline]
    fn to_f32(self) -> f32 {
        self as f32
    }

    #[inline]
    fn add(self, other: Self) -> Self {
        self + other
    }

    #[inline]
    fn sub(self, other: Self) -> Self {
        self - other
    }

    #[inline]
    fn mul(self, other: Self) -> Self {
        self * other
    }

    #[inline]
    fn div(self, other: Self) -> Self {
        self / other
    }
}
