//! Numeric types for HRM operations
//!
//! This module provides minimal numeric trait support needed for HRM operations.
//! This is a temporary solution while hologram-onnx is being migrated to the new architecture.

use std::fmt::Debug;

/// ONNX data types
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(i32)]
#[allow(dead_code)]
pub enum DataType {
    Float32 = 1,
    Float64 = 11,
    Int8 = 3,
    Int16 = 5,
    Int32 = 6,
    Int64 = 7,
    Uint8 = 2,
    Uint16 = 4,
    Uint32 = 12,
    Uint64 = 13,
}

/// Trait for numeric types that can be used in HRM operations
pub trait Numeric: Debug + Copy + Default + PartialOrd + 'static + Send + Sync {
    /// The DataType enum variant for this numeric type
    const DTYPE: DataType;

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

    /// Check if less than
    fn lt(self, other: Self) -> bool;

    /// Check if greater than
    fn gt(self, other: Self) -> bool;
}

// Implementations for standard numeric types

impl Numeric for f32 {
    const DTYPE: DataType = DataType::Float32;

    fn zero() -> Self {
        0.0
    }

    fn one() -> Self {
        1.0
    }

    fn from_i64(value: i64) -> Self {
        value as f32
    }

    fn to_i64(self) -> i64 {
        self as i64
    }

    fn from_f32(value: f32) -> Self {
        value
    }

    fn to_f32(self) -> f32 {
        self
    }

    fn add(self, other: Self) -> Self {
        self + other
    }

    fn sub(self, other: Self) -> Self {
        self - other
    }

    fn mul(self, other: Self) -> Self {
        self * other
    }

    fn div(self, other: Self) -> Self {
        self / other
    }

    fn lt(self, other: Self) -> bool {
        self < other
    }

    fn gt(self, other: Self) -> bool {
        self > other
    }
}

impl Numeric for f64 {
    const DTYPE: DataType = DataType::Float64;

    fn zero() -> Self {
        0.0
    }

    fn one() -> Self {
        1.0
    }

    fn from_i64(value: i64) -> Self {
        value as f64
    }

    fn to_i64(self) -> i64 {
        self as i64
    }

    fn from_f32(value: f32) -> Self {
        value as f64
    }

    fn to_f32(self) -> f32 {
        self as f32
    }

    fn add(self, other: Self) -> Self {
        self + other
    }

    fn sub(self, other: Self) -> Self {
        self - other
    }

    fn mul(self, other: Self) -> Self {
        self * other
    }

    fn div(self, other: Self) -> Self {
        self / other
    }

    fn lt(self, other: Self) -> bool {
        self < other
    }

    fn gt(self, other: Self) -> bool {
        self > other
    }
}

impl Numeric for i32 {
    const DTYPE: DataType = DataType::Int32;

    fn zero() -> Self {
        0
    }

    fn one() -> Self {
        1
    }

    fn from_i64(value: i64) -> Self {
        value as i32
    }

    fn to_i64(self) -> i64 {
        self as i64
    }

    fn from_f32(value: f32) -> Self {
        value as i32
    }

    fn to_f32(self) -> f32 {
        self as f32
    }

    fn add(self, other: Self) -> Self {
        self + other
    }

    fn sub(self, other: Self) -> Self {
        self - other
    }

    fn mul(self, other: Self) -> Self {
        self * other
    }

    fn div(self, other: Self) -> Self {
        self / other
    }

    fn lt(self, other: Self) -> bool {
        self < other
    }

    fn gt(self, other: Self) -> bool {
        self > other
    }
}

impl Numeric for i64 {
    const DTYPE: DataType = DataType::Int64;

    fn zero() -> Self {
        0
    }

    fn one() -> Self {
        1
    }

    fn from_i64(value: i64) -> Self {
        value
    }

    fn to_i64(self) -> i64 {
        self
    }

    fn from_f32(value: f32) -> Self {
        value as i64
    }

    fn to_f32(self) -> f32 {
        self as f32
    }

    fn add(self, other: Self) -> Self {
        self + other
    }

    fn sub(self, other: Self) -> Self {
        self - other
    }

    fn mul(self, other: Self) -> Self {
        self * other
    }

    fn div(self, other: Self) -> Self {
        self / other
    }

    fn lt(self, other: Self) -> bool {
        self < other
    }

    fn gt(self, other: Self) -> bool {
        self > other
    }
}
