//! Auto-generated from Lean verified theorems.
//! This file is a fallback used when the `lean-gen` feature is disabled.
//! It must be kept in sync with the Lean `ExportThresholds.lean` generator.
//! To regenerate: run `cargo build -p sigma --features lean-gen`.

use serde::{Deserialize, Serialize};
use bincode::{Decode, Encode};

/// Thresholds governing the Sigma Kernel's contractivity and dissonance checks.
/// All values are derived from Lean theorems (Rpi_seq_ub_seven, Rlambda1_pos, etc.).
#[derive(Debug, Clone, Serialize, Deserialize, Encode, Decode)]
pub struct Thresholds {
    /// Reference R value for the sequence (F₁ grounding).
    pub tau_r: f64,
    /// Maximum effective length (L_eff) allowed.
    pub l_eff_max: f64,
    /// Upper bound for the RPI sequence (must be ≤ 7 per Lean theorem).
    pub rpi_upper: i32,
    /// λ₁ positivity invariant (must be true per Lean theorem).
    pub lambda1_positive: bool,
    /// Atlas signature tuple (non-negative integers).
    pub atlas_signature: (i32, i32),
    /// Reference R_sc value (matches tau_r in verified Lean export).
    pub r_sc_reference: f64,
    /// Margin for contractivity enforcement (derived from Lean).
    pub contractivity_margin: f64,
}

// Optional: Default values that are Lean-verified (for convenience in tests).
// The actual values should come from the Lean export, but this helps with
// fallback compilation.
impl Default for Thresholds {
    fn default() -> Self {
        Self {
            tau_r: 47.06998778,
            l_eff_max: 0.15,
            rpi_upper: 7,
            lambda1_positive: true,
            atlas_signature: (10, 14),
            r_sc_reference: 47.06998778,
            contractivity_margin: 0.01,
        }
    }
}
