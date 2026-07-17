//! # PARM – Prime-Indexed Recursive Multiplicity Sealed State
//!
//! PARM sealed state is the **canonical commitment primitive** for the
//! Multiplicity Sovereign Core. It provides deterministic, collision-resistant
//! state sealing with optional Archivum witness emission and Triple-Lock
//! (Guardian → Examiner → Publisher) integration.
//!
//! ## Formal Anchor
//!
//! The Rust implementation mirrors the Lean 4 definition in `lean/Core/PARM.lean`:
//!
//! ```lean
//! def sealed_state_loop (v : Nat) : List Nat → Nat
//!   | [] => v
//!   | [last] => (last * last) * (v + last)
//!   | p :: ps => sealed_state_loop (p * (v + p)) ps
//!
//! def sealed_state (primes : List Nat) : Nat :=
//!   match primes with
//!   | [] => 0
//!   | [p] => p * p
//!   | p :: ps => sealed_state_loop (p * p) ps
//! ```
//!
//! Parity is guaranteed by checked arithmetic and identical semantics.

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use chrono::Utc;

#[cfg(feature = "archivum")]
use archivum::{ParmSealProof, WitnessLedger};

#[cfg(test)]
mod tests;

#[cfg(kani)]
mod verification;

pub mod triple_lock;

pub mod PARM;

// ---------------------------------------------------------------------------
// Core types
// ---------------------------------------------------------------------------

/// Witness emitted by the PARM sealing engine for every sealing operation.
///
/// This witness is the machine-readable proof that a specific input sequence
/// sealed to a specific value at a specific time. It is consumed by:
/// - `Archivum` (`ParmSealProof`) for immutable ledger entry
/// - Triple-Lock Guardian/Examiner/Publisher for governance attestation
/// - `LambdaTraceAtom` TEE attestation binding
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParmSealWitness {
    /// SHA-256 digest of the input prime sequence.
    pub input_hash: [u8; 32],
    /// The sealed state value (`u64`).
    pub sealed_value: u64,
    /// Unix timestamp (seconds) of the sealing operation.
    pub timestamp: i64,
}

impl ParmSealWitness {
    /// Create a new `ParmSealWitness` from a sealed value and input bytes.
    pub fn new(sealed_value: u64, input_bytes: &[u8]) -> Self {
        let mut hasher = Sha256::new();
        hasher.update(input_bytes);
        let input_hash = hasher.finalize().into();
        let timestamp = Utc::now().timestamp();
        Self {
            input_hash,
            sealed_value,
            timestamp,
        }
    }
}

/// Errors produced by the PARM sealing engine.
#[derive(Debug, thiserror::Error, PartialEq)]
pub enum ParmError {
    /// The sealed state computation overflowed `u64::MAX`.
    #[error("sealed state overflow")]
    Overflow,
    /// The input prime sequence was empty (no-op sealing).
    #[error("empty prime sequence")]
    EmptyInput,
}

/// The PARM sealing engine.
///
/// All methods are deterministic: identical inputs always produce identical
/// outputs. Overflow is signaled via `ParmError::Overflow` rather than
/// wrapping arithmetic.
#[derive(Debug, Default, Clone, Copy)]
pub struct ParmEngine;

impl ParmEngine {
    /// Compute the sealed state for a sequence of primes.
    ///
    /// This is the **sole semantic authority** for PARM sealed state computation.
    /// The algorithm exactly mirrors `Core.PARM.sealed_state` in Lean 4.
    ///
    /// # Arguments
    ///
    /// * `primes` – Slice of prime numbers (or arbitrary `u64` values).
    ///
    /// # Returns
    ///
    /// * `Ok(sealed_value)` – The deterministic sealed state.
    /// * `Err(ParmError::Overflow)` – If intermediate or final value exceeds `u64::MAX`.
    /// * `Err(ParmError::EmptyInput)` – If the input slice is empty.
    ///
    /// # Examples
    ///
    /// ```
    /// use parm::ParmEngine;
    ///
    /// let engine = ParmEngine;
    /// assert_eq!(engine.sealed_state(&[]), Err(parm::ParmError::EmptyInput));
    /// assert_eq!(engine.sealed_state(&[3]), Ok(9));
    /// assert_eq!(engine.sealed_state(&[3, 3, 3, 2, 2]), Ok(960));
    /// ```
    pub fn sealed_state(&self, primes: &[u64]) -> Result<u64, ParmError> {
        if primes.is_empty() {
            return Err(ParmError::EmptyInput);
        }
        if primes.len() == 1 {
            return primes[0].checked_mul(primes[0]).ok_or(ParmError::Overflow);
        }

        let mut v = primes[0].checked_mul(primes[0]).ok_or(ParmError::Overflow)?;

        for &p in &primes[1..primes.len() - 1] {
            let sum = v.checked_add(p).ok_or(ParmError::Overflow)?;
            v = p.checked_mul(sum).ok_or(ParmError::Overflow)?;
        }

        let last = primes[primes.len() - 1];
        let last_sq = last.checked_mul(last).ok_or(ParmError::Overflow)?;
        let sum = v.checked_add(last).ok_or(ParmError::Overflow)?;
        v = last_sq.checked_mul(sum).ok_or(ParmError::Overflow)?;

        Ok(v)
    }

    /// Compute the sealed state and emit a `ParmSealWitness`.
    ///
    /// This is the preferred entry point for production sealing because it
    /// produces the audit-ready witness in a single call.
    ///
    /// # Arguments
    ///
    /// * `primes` – Slice of prime numbers.
    ///
    /// # Returns
    ///
    /// * `Ok((sealed_value, witness))` – Sealed state and its witness.
    /// * `Err(ParmError)` – On overflow or empty input.
    pub fn seal_with_witness(&self, primes: &[u64]) -> Result<(u64, ParmSealWitness), ParmError> {
        let input_bytes = bytemuck::cast_slice(primes);
        let sealed = self.sealed_state(primes)?;
        let witness = ParmSealWitness::new(sealed, input_bytes);
        Ok((sealed, witness))
    }

    /// Compute the sealed state, emit a witness, and stamp it into `Archivum`.
    ///
    /// Requires the `archivum` feature to be enabled.
    #[cfg(feature = "archivum")]
    pub fn seal_and_archive(
        &self,
        primes: &[u64],
        ledger: &mut WitnessLedger,
    ) -> Result<(u64, ParmSealWitness), ParmError> {
        let (sealed, witness) = self.seal_with_witness(primes)?;
        let proof = archivum::ParmSealProof::new(witness.input_hash, sealed);
        ledger.stamp_parm_seal_proof(&proof).map_err(|_| ParmError::Overflow)?;
        Ok((sealed, witness))
    }
}

// ---------------------------------------------------------------------------
// Triple-Lock re-export
// ---------------------------------------------------------------------------

pub use triple_lock::TripleLockParm;

