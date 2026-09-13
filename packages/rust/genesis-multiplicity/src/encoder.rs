//! Port of `genesis_governance/multiplicity/encoder.py` — quarantined
//! multiplicity encoding logic (ADR-007, ADR-009). Translates scalar states
//! into prime signatures as metadata.

use crate::allocator::PrimeBandAllocator;
use crate::types::{MultiplicityEncoding, SurfaceState};
use std::collections::HashMap;

/// `PRIMES` bank — 10 primes, used only for the sparsity denominator.
pub const PRIMES: [i64; 10] = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29];

/// Multiplicity encoding logic (ADR-007, ADR-009).
pub struct MultiplicityEncoder {
    pub allocator: PrimeBandAllocator,
}

impl MultiplicityEncoder {
    pub fn new(allocator: PrimeBandAllocator) -> Self {
        Self { allocator }
    }

    /// Heuristic: map coherence, stress, and logical_state to primes via the
    /// allocator. Mirrors `int()` truncation toward zero on every exponent.
    pub fn encode(&self, state: &SurfaceState) -> MultiplicityEncoding {
        let mapping = self.allocator.allocate();

        let c_p = mapping.get("coherence").copied().unwrap_or(2);
        let s_p = mapping.get("effective_stress").copied().unwrap_or(3);
        let t_p = mapping.get("threshold_state").copied().unwrap_or(5);
        let l_p = mapping.get("logical_state").copied().unwrap_or(7);
        let f_p = mapping.get("frequency").copied().unwrap_or(13);

        let c_exp = (state.coherence * 5.0).trunc() as i64;
        let s_exp = (state.effective_stress * 10.0).trunc() as i64;

        // Threshold state (ADR-008).
        let v_th = crate::effective_switching_threshold(state.switching_threshold);
        let t_exp = if state.effective_stress > v_th { 1 } else { 0 };

        let l_exp = if state.logical_state_is_on() { 1 } else { 2 };
        let f_exp = (state.frequency * 2.0).trunc() as i64; // simplified

        // Insertion order matters: the Python dict literal order is
        // c_p, s_p, t_p, l_p, f_p and `prime_signature` preserves it.
        let exponents = [
            (c_p, c_exp),
            (s_p, s_exp),
            (t_p, t_exp),
            (l_p, l_exp),
            (f_p, f_exp),
        ];
        let prime_signature = exponents
            .iter()
            .filter(|(_, e)| *e > 0)
            .map(|(p, _)| *p)
            .collect::<Vec<i64>>();

        // Sparsity = active primes / total available primes in bank.
        let sparsity = prime_signature.len() as f64 / PRIMES.len() as f64;

        MultiplicityEncoding {
            prime_signature,
            exponent_vector: HashMap::from(exponents),
            sparsity_index: sparsity,
            locality_score: 1.0, // placeholder
            reconstruction_score: None,
            locality_delta: None,
        }
    }

    /// Attaches fresh multiplicity metadata to a state, mirroring
    /// `state.model_copy(update={"multiplicity": encoding})`. The source
    /// state is left untouched (the "module quarantine" test asserts this).
    pub fn attach(&self, state: &SurfaceState) -> SurfaceState {
        let mut attached = state.clone();
        attached.multiplicity = Some(self.encode(state));
        attached
    }
}
