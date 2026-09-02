pub mod spec;

use ndarray::Array1;
use std::collections::HashMap;
pub use spec::{PrimeMask, ResonanceWord};
use crate::math::{SpectralLinear, PrimeOperator, ResonanceGate};
pub use crate::math::ContractiveOperator;

/// Core trait for all operators in C-PIRTM.
/// Every operator must be contractive (Lipschitz constant < 1).
// Note: ContractiveOperator is now imported from pirtm_core::math.

/// Ω-Trace: Deterministic audit log of operator activations.
pub struct OmegaTrace {
    pub h_encoded: Array1<f64>,
    pub prime_activations: HashMap<u32, Array1<f64>>,
    pub resonance_weights: HashMap<u32, ResonanceWord>,
}

/// CROFLC: Contractive Resonant Operator Field with Lawful Channels.
pub struct CROFLC {
    pub mask: PrimeMask, // Lever 2 Prime Mask
    pub encoder: SpectralLinear,
    pub ops: HashMap<u32, PrimeOperator>, // Keyed by local_prime_id (0-63)
    pub projectors: HashMap<u32, f64>, // Pi_p (stability projectors)
    pub gates: Option<HashMap<u32, ResonanceGate>>,
    pub gen_idx: Vec<usize>,
    pub bio_idx: Vec<usize>,
}

impl CROFLC {
    pub fn forward(&self, x: &Array1<f64>) -> (Array1<f64>, OmegaTrace) {
        // 1. Global Encoding (C)
        let h = self.encoder.forward(x);
        
        let mut agg = Array1::zeros(h.len());
        let mut prime_activations = HashMap::new();
        let mut ws = HashMap::new();
        
        // Resonance inputs
        let x_gen = self.extract_indices(x, &self.gen_idx);
        let x_bio = self.extract_indices(x, &self.bio_idx);

        // 2. Accumulate Prime Channels
        for (m, op) in &self.ops {
            // Lever 2: Prime-Gated Indexing
            // Only process if the prime is set in the mask
            if !self.mask.is_set(*m) {
                continue;
            }

            // Operator field (O_p)
            let z_m_sampled = op.forward(&h);
            
            // Stability Projector (Pi_p)
            let pi_m = self.projectors.get(m).cloned().unwrap_or(0.0);
            let pi_m_sig = 1.0 / (1.0 + (-pi_m).exp()); // Sigmoid projector
            let z_m = z_m_sampled * pi_m_sig;
            
            // Resonance Gate (w_m)
            let w_m = if let Some(ref gates) = self.gates {
                if let Some(gate) = gates.get(m) {
                    gate.forward(&x_gen, &x_bio)
                } else {
                    1.0 / (self.mask.count_ones() as f64)
                }
            } else {
                1.0 / (self.mask.count_ones() as f64)
            };
            
            // Encode as ResonanceWord (Lever 3)
            // For now, assume class 0 for general resonance
            let rw = ResonanceWord::pack_q29_29(0, w_m);
            ws.insert(*m, rw);
            prime_activations.insert(*m, z_m.clone());
            agg = agg + (z_m * w_m);
        }

        
        let trace = OmegaTrace {
            h_encoded: h,
            prime_activations,
            resonance_weights: ws,
        };
        
        (agg, trace)
    }

    fn extract_indices(&self, x: &Array1<f64>, indices: &[usize]) -> Array1<f64> {
        let mut out = Array1::zeros(indices.len());
        for (i, &idx) in indices.iter().enumerate() {
            if idx < x.len() {
                out[i] = x[idx];
            }
        }
        out
    }
}
