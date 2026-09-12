//! `prism_calculator` — the sealed PrismPM calculator model.
//!
//! This crate is the **Twin-side victim** for the Phase Mirror Adversarial
//! Twin lift harness (`tests/adversarial_twin_integration.rs`). It is
//! deliberately small: its semantics are sealed, its arithmetic is checked,
//! and its acceptance vectors are byte-stable so the Twin can lift the model
//! into a prime-indexed dynamical system and attempt to break it.
//!
//! # Model
//!
//! | Object | Meaning |
//! | --- | --- |
//! | `Operation` | `Add`, `Subtract`, `Multiply`, `Divide` — the sealed inductive. |
//! | `Request` | `(op, left, right)` over `i64`. |
//! | `Result Int64` | The arithmetic outcome on the active channel. |
//! | `CalculatorError` | `DivisionByZero`, `Overflow`. |
//! | `AcceptanceVector` | Byte-stable request/response pair for the Hologram oracle. |
//!
//! The calculator does **not** know about primes, contractivity, or spectral
//! radius. Those are Twin-side measurements. This crate owns arithmetic
//! truth only.
//!
//! # See also
//!
//! - [ADR-0002 — Prism–PIRTM Integration](../docs/adr/accepted/0002-Prism-Pirtm-Integration.md)
//! - [Wiki: 05 Building Block View § Whitebox `prism`](https://github.com/UOR-Foundation/UOR-Framework/wiki/05-Building-Block-View#whitebox-prism)

#![no_std]

#[cfg(feature = "alloc")]
extern crate alloc;

/// The sealed four-operation inductive. No fifth constructor is ever added
/// without a LexLean model change and a new PrismPM release contract.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[repr(u8)]
pub enum Operation {
    Add = 2,
    Subtract = 3,
    Multiply = 5,
    Divide = 7,
}

impl Operation {
    /// Canonical prime atlas label for this operation.
    ///
    /// These primes are **Twin-side labels**, not living channels. The
    /// calculator itself never sees them.
    #[must_use]
    pub const fn prime(self) -> u64 {
        self as u64
    }

    /// Atlas index (0..=3) used by the lift harness.
    #[must_use]
    pub const fn atlas_index(self) -> usize {
        match self {
            Self::Add => 0,
            Self::Subtract => 1,
            Self::Multiply => 2,
            Self::Divide => 3,
        }
    }
}

/// A sealed calculator request.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Request {
    pub op: Operation,
    pub left: i64,
    pub right: i64,
}

impl Request {
    #[must_use]
    pub const fn new(op: Operation, left: i64, right: i64) -> Self {
        Self { op, left, right }
    }
}

/// Calculator error discriminant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CalculatorError {
    DivisionByZero,
    Overflow,
}

/// Compute `left op right` with checked overflow.
///
/// This is the **arithmetic ruler**. The Adversarial Twin calls this on every
/// step of a chain; if it returns `Err`, the occupancy update is blocked and
/// the Twin records a boundary event. The ODE does not get to swallow a
/// divide-by-zero.
pub fn calculate(op: Operation, left: i64, right: i64) -> Result<i64, CalculatorError> {
    match op {
        Operation::Add => left.checked_add(right).ok_or(CalculatorError::Overflow),
        Operation::Subtract => left.checked_sub(right).ok_or(CalculatorError::Overflow),
        Operation::Multiply => left.checked_mul(right).ok_or(CalculatorError::Overflow),
        Operation::Divide => {
            if right == 0 {
                Err(CalculatorError::DivisionByZero)
            } else {
                left.checked_div(right).ok_or(CalculatorError::Overflow)
            }
        }
    }
}

/// Byte-stable acceptance vector: a request/response pair for the Hologram
/// oracle. The Twin may replay these to prove the lift does not desync the
/// discrete discriminant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AcceptanceVector {
    pub request: Request,
    pub expected: Result<i64, CalculatorError>,
}

impl AcceptanceVector {
    #[must_use]
    pub const fn new(request: Request, expected: Result<i64, CalculatorError>) -> Self {
        Self { request, expected }
    }
}

/// Canonical acceptance vectors shipped with the model.
///
/// These are the sealed vectors the compressive Sentinel (`Sigma`) must
/// admit. They cover the four operations, the divide-by-zero pole, and the
/// overflow boundary.
pub const ACCEPTANCE_VECTORS: &[AcceptanceVector] = &[
    AcceptanceVector::new(
        Request::new(Operation::Add, 1, 2),
        Ok(3),
    ),
    AcceptanceVector::new(
        Request::new(Operation::Subtract, 10, 4),
        Ok(6),
    ),
    AcceptanceVector::new(
        Request::new(Operation::Multiply, 6, 7),
        Ok(42),
    ),
    AcceptanceVector::new(
        Request::new(Operation::Divide, 100, 4),
        Ok(25),
    ),
    AcceptanceVector::new(
        Request::new(Operation::Divide, 6, 0),
        Err(CalculatorError::DivisionByZero),
    ),
    AcceptanceVector::new(
        Request::new(Operation::Multiply, i64::MAX, 2),
        Err(CalculatorError::Overflow),
    ),
];