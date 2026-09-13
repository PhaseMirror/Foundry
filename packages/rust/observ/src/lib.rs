//! The observability calculus kernel — ADRs 0022–0028.
//!
//! `observ` implements the measurement-map geometry of the JHaines 2026
//! observable-algebra papers as an exact, floating-point-free Rust kernel:
//!
//! - `rat` — exact `i128` rationals (no `f32`/`f64` anywhere, ADR-0021);
//! - `la` — exact linear algebra (rref, kernels, obstruction dimension);
//! - `system` — the wire `MeasurementProgram` and its validation;
//! - `sector` — reference-sector projectors and admissibility (ADR-0023);
//! - `reversal` — Walsh–Hadamard reversal-space coding (ADR-0024/0027);
//! - `claim` — the six-component claim gate (ADR-0026);
//! - `kernel` — the fail-closed gate and the verdict artifact;
//! - `defect`/`levers`/`receipt` — the named English defect language, levers,
//!   and the CRMF PWEH-binding receipt.
//!
//! ## Scope
//!
//! This crate **measures** and **issues receipts**; it is not an archival layer.
//! Storage is only CRMF + Archivum — there is no WORM anywhere (ADR-0013).
//! The Lean mirror of the gate (`lean_mirror`) is `None` until it actually
//! lands; the Kani harness manifest is reported on every receipt.
//!
//! ## Integer-only substrate
//!
//! Every coefficient is an exact ratio of `i128` integers. Cumulative maps,
//! null filtrations, witness spaces, Walsh characters (n/2^N), and design
//! gains are all exact — repeated runs are bitwise reproducible.

pub mod claim;
pub mod defect;
pub mod kernel;
pub mod la;
pub mod levers;
pub mod rat;
pub mod receipt;
pub mod reversal;
pub mod sector;
pub mod system;

pub use defect::{DefectCode, ObservDefect};
pub use kernel::{GateSignal, ObservVerdict};
pub use rat::Q;
pub use receipt::Receipt;
pub use system::{ClaimStatus, MeasurementProgram, StageKind};

/// Kernel version of the observability calculus.
pub const KERNEL_VERSION: &str = "observ-0.1.0";
