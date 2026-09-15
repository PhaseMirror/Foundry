//! The `EnsembleManifest` and the PrismPM `.holo` compile veto gate
//! (ADR-0066 §"The Ensemble Manifest Structure").
//!
//! A manufactured artifact is only entered into the PIRTM manifold when the
//! PrismPM factory can produce it under the manifold's contractivity law. The
//! factory emits an `EnsembleManifest`; the manifold-side `compile` gate is
//! fail-closed:
//!
//! * `prime_topology` must name a lane of the overlay (`Add → p₁=2`,
//!   `Multiply → p₂=3`);
//! * the chain's fixed-point spectral radius must be strictly below
//!   `spectral_limit` (a scaled bound derived from `1 − ε`);
//! * the `crmf_seal` must reproduce over the canonical manifest core.

use serde::{Deserialize, Serialize};

use crate::canonical::sha256_canonical;
use crate::poseidon2::Poseidon2Sponge;
use crate::tensor::CONTRACTIVITY_SCALE;

/// PrismPM calculator operations lifted onto the prime-indexed overlay per
/// ADR-0066 §"1. Semantic and Dimensional Mapping".
///
/// Note this overlay is the ADR's own: `Add → 2`, `Multiply → 3`. It is
/// intentionally **not** the calculator's internal machine identifier table
/// (`crates/prism-calculator` additionally labels `Subtract=3, Multiply=5,
/// Divide=7`); the two encodings never cross the boundary.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[repr(u8)]
pub enum PrismOperation {
    /// `Add → p₁ = 2` (the sole graph operation; computes the additive gauge).
    Add = 2,
    /// `Multiply → p₂ = 3` (the reciprocal graph operation; computes the
    /// multiplicative gauge).
    Multiply = 3,
}

impl PrismOperation {
    /// The ADR prime index (`Add = 2`, `Multiply = 3`).
    #[must_use]
    pub const fn prime(&self) -> u8 {
        match self {
            Self::Add => 2,
            Self::Multiply => 3,
        }
    }

    /// Canonical one-byte encoding.
    #[must_use]
    pub const fn to_byte(&self) -> u8 {
        self.prime()
    }
}

impl TryFrom<u8> for PrismOperation {
    type Error = EnsembleError;

    fn try_from(b: u8) -> Result<Self, Self::Error> {
        match b {
            2 => Ok(Self::Add),
            3 => Ok(Self::Multiply),
            _ => Err(EnsembleError::InvalidTopology(b)),
        }
    }
}

/// Failure modes of the ensemble compile/entry gate.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum EnsembleError {
    #[error("prism topology {0} is not in the Add/Multiply prime overlay")]
    InvalidTopology(u8),
    #[error("spectral radius over the chain breaches the ensemble spectral limit")]
    RadiusBreachesSpectralLimit,
    #[error("crmf_seal does not reproduce over the manifest core")]
    SealMismatch,
    #[error("operation lane {0} is not in the manifest's prime topology")]
    LaneOutsideTopology(u8),
    #[error("manifest length prefix mismatch in canonical round-trip")]
    LengthMismatch,
}

/// Provisioned manifold byte-budget for a compact, Kani-friendly gate core.
pub const MANIFEST_CORE_WIDTH: usize = 32 /* uor_identity */ + 8 /* prime_topology u64 */ + 8 /* spectral_limit u64 */ + 32 /* multiplicity_signature */;

/// The artifact manifest emitted by the PrimS entry compiler.
///
/// Canonical BCS layout (fixed order, big-endian integers):
///
/// | Field | Width |
/// | --- | --- |
/// | `uor_identity` | 32 |
/// | `prime_topology` (`u64`, 2 or 3) | 8 |
/// | `spectral_limit` (fixed-point ρ bound) | 8 |
/// | `multiplicity_signature` | 32 |
/// | `crmf_seal` (sponge over the canonical core) | 32 |
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct EnsembleManifest {
    /// UOR 256-bit identity of the entering ensemble.
    pub uor_identity: [u8; 32],
    /// The prime-indexed overlay lane this artifact admits (`Add=2`/`Multiply=3`).
    pub prime_topology: u64,
    /// Fixed-point spectral limit against which the chain radius is judged.
    pub spectral_limit: u64,
    /// Deterministic multiplicity signature of the proven operation chain.
    pub multiplicity_signature: [u8; 32],
    /// `crmf_validity_seal` over the canonical manifest core.
    pub crmf_seal: [u8; 32],
}

impl EnsembleManifest {
    /// Canonical (BCS-rule) bytes of the manifest **core** — everything the
    /// seal commits to, except the seal itself.
    #[must_use]
    pub fn to_core_bytes(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(MANIFEST_CORE_WIDTH);
        out.extend_from_slice(&self.uor_identity);
        out.extend_from_slice(&self.prime_topology.to_be_bytes());
        out.extend_from_slice(&self.spectral_limit.to_be_bytes());
        out.extend_from_slice(&self.multiplicity_signature);
        debug_assert_eq!(out.len(), MANIFEST_CORE_WIDTH);
        out
    }

    /// Canonical BCS bytes of the whole manifest (core + seal).
    #[must_use]
    pub fn to_canonical_bytes(&self) -> Vec<u8> {
        let mut out = self.to_core_bytes();
        out.extend_from_slice(&self.crmf_seal);
        out
    }

    /// Recompute the manifest seal (failure telemetry → `crmf_validity_seal`).
    #[must_use]
    pub fn compute_seal(&self) -> [u8; 32] {
        Poseidon2Sponge::seal(&self.to_core_bytes())
    }

    /// Fail-closed verification of the seal over the canonical core.
    pub fn verify_seal(&self) -> Result<(), EnsembleError> {
        if self.compute_seal() == self.crmf_seal {
            Ok(())
        } else {
            Err(EnsembleError::SealMismatch)
        }
    }
}

/// Deterministic multiplicity signature of an operation chain: SHA-256 over
/// the byte-exact concatenation of each op's prime index.
#[must_use]
pub fn multiplicity_signature(chain_ops: &[u8]) -> [u8; 32] {
    sha256_canonical(chain_ops)
}

/// The PrimS factory's entry point. Provably fails closed: **any** chain whose
/// fixed-point spectral radius is at or above `spectral_limit` is rejected.
///
/// `chain_radius_scaled` is produced at the telemetry boundary by
/// [`crate::ace::radius_scaled`]; the gate itself only compares scaled
/// integers.
pub fn compile_manifest(
    uor_identity: [u8; 32],
    prime_topology: u64,
    spectral_limit: u64,
    chain_ops: &[PrismOperation],
    chain_radius_scaled: u64,
) -> Result<EnsembleManifest, EnsembleError> {
    let topo_byte: u8 = u8::try_from(prime_topology)
        .map_err(|_| EnsembleError::InvalidTopology(prime_topology as u8))?;
    let topology = PrismOperation::try_from(topo_byte)?;
    // Every lane must belong to the manifest's overlay.
    let mut ops_bytes = Vec::with_capacity(chain_ops.len());
    for op in chain_ops {
        if op.prime() != topology.prime() {
            return Err(EnsembleError::LaneOutsideTopology(op.prime()));
        }
        ops_bytes.push(op.to_byte());
    }
    // The veto: contractivity limit judged in fixed point.
    if chain_radius_scaled >= spectral_limit {
        return Err(EnsembleError::RadiusBreachesSpectralLimit);
    }
    let mut manifest = EnsembleManifest {
        uor_identity,
        prime_topology,
        spectral_limit,
        multiplicity_signature: multiplicity_signature(&ops_bytes),
        crmf_seal: [0u8; 32],
    };
    manifest.crmf_seal = manifest.compute_seal();
    Ok(manifest)
}

/// Default ensemble spectral limit: `(1 − ε)·1e9` in fixed point.
#[must_use]
pub const fn default_spectral_limit() -> u64 {
    (CONTRACTIVITY_SCALE as f64 * (1.0 - crate::ace::CONTRACTIVITY_EPSILON)) as u64
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::tensor::GainMatrix;

    const ID: [u8; 32] = [0x0a; 32];

    #[test]
    fn compiles_contractive_add_chain() {
        let manifest = compile_manifest(ID, 2, default_spectral_limit(), &[PrismOperation::Add, PrismOperation::Add], 500_000_000)
            .expect("contractive chain compiles");
        assert_eq!(manifest.verify_seal(), Ok(()));
        assert_eq!(manifest.multiplicity_signature, multiplicity_signature(&[2, 2]));
    }

    #[test]
    fn rejects_expansive_chain_before_sealing() {
        let result = compile_manifest(
            ID,
            3,
            default_spectral_limit(),
            &[PrismOperation::Multiply; 4],
            default_spectral_limit(), // r == limit => veto
        );
        assert_eq!(result, Err(EnsembleError::RadiusBreachesSpectralLimit));
    }

    #[test]
    fn rejects_foreign_lane_in_chain() {
        let result = compile_manifest(ID, 2, default_spectral_limit(), &[PrismOperation::Multiply], 0);
        assert_eq!(result, Err(EnsembleError::LaneOutsideTopology(3)));
    }

    #[test]
    fn rejects_invalid_topology() {
        let result = compile_manifest(ID, 7, default_spectral_limit(), &[], 0);
        assert!(matches!(result, Err(EnsembleError::InvalidTopology(7))));
    }

    #[test]
    fn overlay_enum_matches_adr_primes() {
        assert_eq!(PrismOperation::Add.prime(), 2);
        assert_eq!(PrismOperation::Multiply.prime(), 3);
        assert_eq!(PrismOperation::Add as u8, 2);
    }

    #[test]
    fn seal_detects_tampering() {
        let mut manifest = compile_manifest(ID, 2, default_spectral_limit(), &[PrismOperation::Add], 300_000_000)
            .expect("contractive");
        assert_eq!(manifest.verify_seal(), Ok(()));
        manifest.spectral_limit += 1;
        assert_eq!(manifest.verify_seal(), Err(EnsembleError::SealMismatch));
    }

    /// End-to-end: adversarial injection `ρ = 1.5` upstream ⇒ radius_scaled ≥
    /// bound ⇒ the ensemble refuses to enter.
    #[test]
    fn adversarial_gain_refuses_entry() {
        let mut psi = GainMatrix::new_2x2();
        psi.set_weights(1.0, 0.5, 0.5, 1.0);
        let radius = crate::ace::radius_scaled(&psi);
        assert!(radius >= default_spectral_limit());
        let result = compile_manifest(ID, 2, default_spectral_limit(), &[PrismOperation::Add; 8], radius);
        assert_eq!(result, Err(EnsembleError::RadiusBreachesSpectralLimit));
    }
}