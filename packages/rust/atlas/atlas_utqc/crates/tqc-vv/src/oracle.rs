//! Loading and integrity-checking external oracle artifacts.
//!
//! The F1 constants are embedded at compile time; [`F1Constants::sha256`] recomputes the
//! digest so a witness can assert it matches the pin recorded in `model/oracles.toml`
//! (Law L5: re-derive, never trust).

use serde::Deserialize;
use sha2::{Digest, Sha256};

/// The committed F1 Atlas constants (the authoritative oracle artifact).
pub const F1_JSON: &str = include_str!("../../../oracles/f1/atlas-constants.json");

/// The parameter triple F1 was extracted at.
#[derive(Debug, Clone, Deserialize)]
pub struct F1Params {
    /// Scope `q`.
    pub scope_q: u32,
    /// Modality `T`.
    #[serde(rename = "modality_T")]
    pub modality_t: u32,
    /// Context `O`.
    #[serde(rename = "context_O")]
    pub context_o: u32,
}

/// Class / belt constants.
#[derive(Debug, Clone, Deserialize)]
pub struct F1Classes {
    /// Class count.
    pub count: u64,
    /// Class stride.
    pub stride: u64,
    /// Belt extent.
    pub belt_extent: u64,
    /// Belt factorizations, each `[a, b]` with `a·b = belt_extent`.
    pub belt_factorizations: Vec<Vec<u64>>,
}

/// Generator orders.
#[derive(Debug, Clone, Deserialize)]
pub struct F1Generators {
    /// Order of `σ`.
    pub sigma_order: u32,
    /// Order of `τ`.
    pub tau_order: u32,
    /// Order of `μ`.
    pub mu_order: u32,
}

/// Spectral constants.
#[derive(Debug, Clone, Deserialize)]
pub struct F1Spectrum {
    /// Block eigenvalues `{10,7,2,-1}`.
    pub eigenvalues: Vec<i64>,
    /// Multiplicities `{1,2,7,14}`.
    pub multiplicities: Vec<u64>,
    /// Signature `[positive, negative]`.
    pub signature: Vec<u64>,
    /// Trace.
    pub trace: i64,
    /// Carrier dimension.
    pub dim: u64,
    /// Whether the operator is indefinite.
    pub indefinite: bool,
}

/// Coxeter constants.
#[derive(Debug, Clone, Deserialize)]
pub struct F1Coxeter {
    /// Coxeter number `h`.
    pub number_h: u32,
    /// Exponents.
    pub exponents: Vec<u32>,
    /// Sum of exponents.
    pub exponent_sum: u32,
    /// Rank.
    pub rank: u32,
}

/// E8 root-lattice seed constants.
#[derive(Debug, Clone, Deserialize)]
pub struct F1E8Seed {
    /// Cartan diagonal (`2`).
    pub cartan_diag: i64,
    /// Gram scale factor (`Gram = scale × Cartan`).
    pub gram_scale: i64,
    /// Gram diagonal (`8`).
    pub gram_diag: i64,
    /// Gram off-diagonal edge weight (`-4`).
    pub gram_edge: i64,
    /// Whether the Gram is positive semidefinite.
    pub psd: bool,
}

/// Modular-form constants.
#[derive(Debug, Clone, Deserialize)]
pub struct F1Modular {
    /// Weight `T·O/2`.
    pub weight: u32,
    /// The `1728` constant.
    pub constant: i64,
    /// `E4` leading `q`-coefficients.
    #[serde(rename = "E4")]
    pub e4: Vec<i64>,
    /// `E6` leading `q`-coefficients.
    #[serde(rename = "E6")]
    pub e6: Vec<i64>,
    /// `Δ` leading `q`-coefficients.
    #[serde(rename = "Delta")]
    pub delta: Vec<i64>,
}

/// The whole F1 oracle.
#[derive(Debug, Clone, Deserialize)]
pub struct F1Constants {
    /// Parameters.
    pub params: F1Params,
    /// Class / belt.
    pub classes: F1Classes,
    /// Generators.
    pub generators: F1Generators,
    /// Spectrum.
    pub spectrum: F1Spectrum,
    /// Coxeter.
    pub coxeter: F1Coxeter,
    /// E8 seed.
    pub e8_seed: F1E8Seed,
    /// Modular.
    pub modular: F1Modular,
}

impl F1Constants {
    /// Parse the embedded F1 oracle.
    ///
    /// # Errors
    /// Returns the serde error text if the JSON is malformed.
    pub fn load() -> Result<Self, String> {
        serde_json::from_str(F1_JSON).map_err(|e| format!("F1 oracle JSON: {e}"))
    }

    /// The sha256 (hex) of the committed artifact, for provenance verification.
    #[must_use]
    pub fn sha256() -> String {
        let mut h = Sha256::new();
        h.update(F1_JSON.as_bytes());
        hex::encode(h.finalize())
    }
}
