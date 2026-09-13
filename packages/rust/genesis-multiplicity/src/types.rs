//! Port of `genesis_governance/types.py` (subsets used by the multiplicity
//! modules): `MultiplicityEncoding` and `SurfaceState`.
//!
//! The port drops the pydantic base-model bookkeeping (`schema_version`,
//! `created_at`, `run_id`, `source_adr_ids`, `tier`, `provenance`) because no
//! multiplicity computation reads it. All fields these modules read are
//! preserved with identical semantics.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Multiplicity of a surface state: a prime signature annotated with the
/// exponent vector, sparsity, locality, and (when available) the
/// reconstruction score and locality delta.
///
/// Mirrors `MultiplicityEncoding` (pydantic). `prime_signature` preserves the
/// insertion order of the encoder (active primes in band-mapping order), which
/// Python dicts preserve and the tests rely on.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MultiplicityEncoding {
    #[serde(default)]
    pub prime_signature: Vec<i64>,
    #[serde(default)]
    pub exponent_vector: HashMap<i64, i64>,
    #[serde(default)]
    pub sparsity_index: f64,
    #[serde(default)]
    pub locality_score: f64,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub reconstruction_score: Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub locality_delta: Option<f64>,
}

impl MultiplicityEncoding {
    /// Pydantic-equivalent constructor: `prime_signature = []`,
    /// `exponent_vector = {}`, `sparsity_index = 0.0`,
    /// `locality_score = 0.0`, `reconstruction_score = None`,
    /// `locality_delta = None`.
    pub fn with_exponent_vector(exponent_vector: HashMap<i64, i64>) -> Self {
        Self {
            prime_signature: Vec::new(),
            exponent_vector,
            sparsity_index: 0.0,
            locality_score: 0.0,
            reconstruction_score: None,
            locality_delta: None,
        }
    }
}

/// `default_logical_state` mirrors the pydantic field default `"ON"`: the
/// value materializes when the key is absent in JSON, while an explicit
/// `null` still deserializes to `None` (which encodes as the `"OFF"` branch).
fn default_logical_state() -> Option<String> {
    Some(String::from("ON"))
}

/// A scalar surface state (C_X, S_eff, and Lane-C extensions).
///
/// Mirrors `SurfaceState`. Only the fields consulted by the encoder/decoder
/// are operative here; the rest (grounding, alignment, impedance, ...) are
/// carried for round-trip fidelity.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SurfaceState {
    pub substrate: String,
    /// C_X
    pub coherence: f64,
    /// C_X*
    #[serde(default)]
    pub stability_threshold: f64,
    /// S_eff
    pub effective_stress: f64,
    /// G_X
    #[serde(default)]
    pub grounding: f64,
    /// A_X
    #[serde(default)]
    pub alignment: f64,
    /// Omega_X
    #[serde(default)]
    pub impedance: f64,
    /// D_k,X
    #[serde(default)]
    pub kinematic_drag: f64,
    /// omega
    #[serde(default)]
    pub frequency: f64,
    #[serde(default)]
    pub timestamp: f64,
    #[serde(default)]
    pub multiplicity: Option<MultiplicityEncoding>,
    /// V_th (ADR-008); default `None`, read via `or 0.5` semantics.
    #[serde(default)]
    pub switching_threshold: Option<f64>,
    /// Delta (hysteresis band)
    #[serde(default)]
    pub hysteresis_band: Option<f64>,
    /// `"ON"` / `"OFF"`; pydantic default `"ON"`.
    #[serde(default = "default_logical_state")]
    pub logical_state: Option<String>,
}

impl SurfaceState {
    /// `state.logical_state == "ON"` — the encoder's `l_exp` discriminator.
    pub fn logical_state_is_on(&self) -> bool {
        self.logical_state.as_deref() == Some("ON")
    }
}

impl Default for SurfaceState {
    fn default() -> Self {
        Self {
            substrate: String::new(),
            coherence: 0.0,
            stability_threshold: 0.0,
            effective_stress: 0.0,
            grounding: 0.0,
            alignment: 0.0,
            impedance: 1.0,
            kinematic_drag: 0.0,
            frequency: 1.0,
            timestamp: 0.0,
            multiplicity: None,
            switching_threshold: None,
            hysteresis_band: None,
            // pydantic default `"ON"`.
            logical_state: Some(String::from("ON")),
        }
    }
}
