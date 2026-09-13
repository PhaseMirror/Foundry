//! # UCC — Universal Closure Calculator kernel (ADR-0014)
//!
//! Production-grade core of the year-one (Q0) UCC product slice:
//!
//! - the **sextuple** wire schema `(X, ∘, α, μ, F, Δ)` ([`system::SystemInput`],
//!   `docs/specs/ucc_sextuple_v1.md`);
//! - the **L0 lawfulness gate** ([`kernel::Kernel`]) that closes a partial system
//!   only when every law holds, returning the four artifacts: Closure, Δ (each
//!   named in English a node can act on), Levers, and a canonical Receipt;
//! - the **receipt** encoding ([`receipt::Receipt`]) per ADR-0021 (fixed field
//!   order, ULEB128 prefixes, no floats), bound through the CRMF PWEH chain.
//!
//! ## Honesty contract (from the UCC audit, `docs/Universal_Closure/Universal
//! Closure Calculator Audit.md`)
//!
//! - Δ is a *structural* contractivity/associator defect of the kernel boundary.
//!   This crate asserts no connection to, or consequence for, the Riemann
//!   Hypothesis; that discussion remains in the paper (ADR-0014 non-goal).
//! - Receipts are real: input digest, kernel version, build id, timestamp, and
//!   the actual Kani harness set. Nothing is self-PASSED and no verifier log is
//!   fabricated.
//! - The gate reuses the ADR-0013 verified latch (`crmf::failgate`, integer
//!   scaled), so "kill" is a real non-maskable latch, not a log string.

pub mod defect;
pub mod kernel;
pub mod levers;
pub mod receipt;
pub mod system;

pub use defect::{DefectCode, UccDefect};
pub use kernel::{Closure, Component, Kernel, UccError, UccVerdict};
pub use levers::Lever;
pub use receipt::Receipt;
pub use system::{
    CompositionOp, EndoKind, Endomorphism, NodeRef, Relation, SystemInput,
    ALPHA_JOIN_IDENTITY, ALPHA_UNION_IDENTITY, LAWFUL_RECURSION_VERSION,
};

/// Kernel version tag. The Q0 repository-hygiene gate requires the receipt to
/// cite a versioned kernel (ADR-0014 §Q0).
pub const KERNEL_VERSION: &str = "0.1.0";