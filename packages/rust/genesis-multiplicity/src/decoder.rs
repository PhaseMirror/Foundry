//! Port of `genesis_governance/multiplicity/decoder.py` — quarantined
//! multiplicity decoding logic (ADR-007, ADR-009). Reconstructs approximate
//! scalar states from prime signatures.

use crate::allocator::PrimeBandAllocator;
use crate::types::{MultiplicityEncoding, SurfaceState};
use std::collections::HashMap;

/// Reconstructed scalar state, replacing the Python 4-tuple
/// `(recon_coherence, recon_stress, recon_state, recon_threshold_exceeded)`.
#[derive(Debug, Clone, PartialEq)]
pub struct DecodedState {
    pub coherence: f64,
    pub stress: f64,
    pub logical_state: String,
    pub threshold_exceeded: bool,
}

/// Multiplicity decoding logic (ADR-007, ADR-009).
pub struct MultiplicityDecoder {
    pub allocator: PrimeBandAllocator,
}

impl MultiplicityDecoder {
    pub fn new(allocator: PrimeBandAllocator) -> Self {
        Self { allocator }
    }

    /// Reconstructs state from the exponent vector via dynamic mapping.
    pub fn decode(&self, encoding: &MultiplicityEncoding) -> DecodedState {
        let mapping = self.allocator.allocate();

        let c_p = mapping.get("coherence").copied().unwrap_or(2);
        let s_p = mapping.get("effective_stress").copied().unwrap_or(3);
        let t_p = mapping.get("threshold_state").copied().unwrap_or(5);
        let l_p = mapping.get("logical_state").copied().unwrap_or(7);

        let c_exp = encoding.exponent_vector.get(&c_p).copied().unwrap_or(0) as f64;
        let s_exp = encoding.exponent_vector.get(&s_p).copied().unwrap_or(0) as f64;
        let t_exp = encoder_exponent(encoding, t_p);
        let l_exp = encoder_exponent(encoding, l_p);

        // Center of the quantization bins.
        let coherence = (c_exp + 0.5) / 5.0;
        let stress = (s_exp + 0.5) / 10.0;
        let threshold_exceeded = t_exp == 1;
        let logical_state = if l_exp == 1 { "ON" } else { "OFF" };

        DecodedState {
            coherence,
            stress,
            logical_state: logical_state.to_string(),
            threshold_exceeded,
        }
    }

    /// Computes the reconstruction score (1.0 = perfect match), including the
    /// categorical `logical_state` penalty. Mirrors
    /// `compute_reconstruction_score`.
    pub fn compute_reconstruction_score(
        &self,
        original_state: &SurfaceState,
        encoding: &MultiplicityEncoding,
    ) -> f64 {
        let recon = self.decode(encoding);

        let orig_c = original_state.coherence;
        let orig_s = original_state.effective_stress;
        let orig_state = original_state.logical_state_is_on();
        let v_th = crate::effective_switching_threshold(original_state.switching_threshold);
        let orig_th = orig_s > v_th;

        // L2 distance for numerical values.
        let mut dist =
            ((orig_c - recon.coherence).powi(2) + (orig_s - recon.stress).powi(2)).sqrt();

        // Categorical penalty for logical state mismatch.
        let recon_state = recon.logical_state == "ON";
        if recon_state != orig_state {
            dist += 0.5; // substantial penalty
        }
        // Penalty for threshold state mismatch.
        if recon.threshold_exceeded != orig_th {
            dist += 0.3;
        }

        (-dist * 2.0).exp()
    }

    /// Measures locality delta: the max change under a single-exponent
    /// perturbation. Mirrors `validate_locality`.
    pub fn validate_locality(
        &self,
        encoding: &MultiplicityEncoding,
        perturbation: &HashMap<i64, i64>,
    ) -> f64 {
        // Original reconstruction.
        let base = self.decode(encoding);

        // Perturbed reconstruction.
        let mut p_vector = encoding.exponent_vector.clone();
        for (p, d) in perturbation {
            let entry = p_vector.entry(*p).or_insert(0);
            *entry = (*entry + d).max(0);
        }
        let p_encoding = MultiplicityEncoding::with_exponent_vector(p_vector);
        let p = self.decode(&p_encoding);

        // Delta.
        let mut delta =
            ((base.coherence - p.coherence).powi(2) + (base.stress - p.stress).powi(2)).sqrt();
        if base.logical_state != p.logical_state {
            delta += 0.5;
        }
        if base.threshold_exceeded != p.threshold_exceeded {
            delta += 0.3;
        }
        delta
    }
}

fn encoder_exponent(encoding: &MultiplicityEncoding, prime: i64) -> i64 {
    encoding.exponent_vector.get(&prime).copied().unwrap_or(0)
}
