//! # `pirtm-engine` — PIRTM Arithmetic Control Engine (ADR-0066)
//!
//! Production-grade Rust implementation of the **PrismPM ↔ PIRTM
//! interoperability veto gate** mandated by
//! [`docs/adr/accepted/0066-PrismPM and Langlands Prism.md`](../../../docs/adr/accepted/0066-PrismPM%20and%20Langlands%20Prism.md).
//!
//! ## Architecture
//!
//! | Module | Responsibility | ADR-0066 section |
//! | --- | --- | --- |
//! | [`tensor`] | 2×2 `GainMatrix` over the prime-indexed tensor overlay (`Add→p₁=2`, `Multiply→p₂=3`), spectral radius `ρ(Ψ)`. | §1 Semantic and Dimensional Mapping |
//! | [`ace`] | Arithmetic Control Engine: fail-closed `SIG_GOV_KILL` veto when `ρ(Ψ) ≥ 1−ε`, plus the scaled fixed-point governance gate over CRMF envelopes. | §2 Rust/Kani Integration Harness, §The Veto Gate |
//! | [`canonical`] | `UnsignedCrmfEnvelope` and byte-exact canonical BCS packing rules (fixed field order, big-endian integers, length-prefixed metadata). | §Universal BCS Packing Rules |
//! | [`manifest`] | `EnsembleManifest` (`uor_identity`, `prime_topology`, `spectral_limit`, `multiplicity_signature`, `crmf_seal`) and the `.holo` compile gate. | §The Ensemble Manifest Structure |
//! | [`poseidon2`] | Poseidon2-style sponge (`t=9, r=8`) producing the 256-bit `crmf_validity_seal`. | §Cryptographic Bridging |
//! | [`recovery`] | Phase D dual-signature `resumption_request` and the 9-step ACE verification gate (L0_HALT release). | §Phase D Recovery Sequence / §The ACE Verification Gate |
//!
//! ## Guarantee proved by the Kani harnesses (`tests/`)
//!
//! 1. **The Veto:** a semantically-valid PrismPM model (zero-sorry Lean 4
//!    proofs) is still vetoed by ACE when the injected gain matrix breaches
//!    the contractivity bound — `Err(SigGovKill::ExpansiveState)`.
//! 2. **BCS canonical injectivity:** equal canonical byte streams iff equal
//!    envelopes — the zero-knowledge absorption prerequisite.
//! 3. **Fail-closed halting:** any CRMF envelope asserting `Λ_m ≥ 1.0`
//!    (i.e. `lambda_m ≥ CONTRACTIVITY_SCALE`) is rejected by the governance
//!    gate.
//! 4. **Phase D:** the 9-condition ACE resumption gate releases `L0_HALT`
//!    only when chain-continuity, freshness, content-binding, and
//!    dual-authorization conditions all hold.
//!
//! ## Deliberate minimal seams (externally documented)
//!
//! - The Poseidon2 permutation is instantiated over the M61 prime field
//!   (2^61−1) as a structurally identical `t=9, r=8` sponge; the BN254
//!   scalar-field substitution point (arkworks `crmf/src/poseidon2.rs`) is a
//!   drop-in backend behind the same `sponge_absorb` interface.
//! - The spectral-radius-to-fixed-point conversion happens at the telemetry
//!   boundary; every governance gate compares scaled `u64` integers only, so
//!   the gates stay `f64`-free and fully model-checkable.

pub mod ace;
pub mod canonical;
pub mod manifest;
pub mod poseidon2;
pub mod recovery;
pub mod tensor;

pub use ace::{SigGovKill, evaluate_ace_governance_gate, evaluate_spectral_radius, verify_transition};
pub use canonical::{MetricBounds, UnsignedCrmfEnvelope};
pub use manifest::{EnsembleManifest, PrismOperation};