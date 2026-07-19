use crate::{GoldilocksField, PrimeMask, ResonanceWord, MODULUS};
use std::collections::HashMap;

/// Lever 4 — Hamiltonian (Normative)
/// Sparse Hamiltonian representation over N0_CIRCUIT zeros.
/// H = \sum_i c_i P_i where c_i is a resonance-modulated coefficient
/// and P_i is a prime-gated potential term.
pub struct Hamiltonian {
    pub n_zeros: usize,
    pub terms: Vec<HamiltonianTerm>,
}

pub struct HamiltonianTerm {
    /// Lever 2 Prime Mask gating this term.
    pub mask: PrimeMask,
    
    /// Base coefficient (as a field element).
    pub coeff: GoldilocksField,
    
    /// Resonance class modulation (Lever 3).
    /// If Some, the term is multiplied by the resonance word's payload.
    pub resonance_class: Option<u8>,
}

impl Hamiltonian {
    pub fn new(n_zeros: usize) -> Self {
        Self {
            n_zeros,
            terms: Vec::new(),
        }
    }

    pub fn add_term(&mut self, mask: PrimeMask, coeff: GoldilocksField, resonance_class: Option<u8>) {
        self.terms.push(HamiltonianTerm {
            mask,
            coeff,
            resonance_class,
        });
    }

    /// Evaluate the effective Hamiltonian coefficients given an active mask and resonance state.
    pub fn evaluate(&self, active_mask: PrimeMask, resonance_state: &HashMap<u8, ResonanceWord>) -> Vec<GoldilocksField> {
        let mut effective_coeffs = Vec::with_capacity(self.terms.len());
        
        for term in &self.terms {
            // Prime gating: only include terms whose mask intersects with active_mask
            let intersection = term.mask.and(active_mask);
            if intersection == PrimeMask::EMPTY && term.mask != PrimeMask::EMPTY {
                continue;
            }

            let mut val = term.coeff;

            // Resonance modulation
            if let Some(c) = term.resonance_class {
                if let Some(rw) = resonance_state.get(&c) {
                    // Multiply by resonance payload
                    val = val * rw.to_field();
                }
            }

            effective_coeffs.push(val);
        }
        
        effective_coeffs
    }
}

/// ZetaCell Update Rule (Placeholder for simulation)
/// This represents how Hamiltonian evolution affects the spectral witness.
pub struct ZetaCell {
    pub hamiltonian: Hamiltonian,
    pub state: Vec<GoldilocksField>, // Current eigenvalues/zeros
}

impl ZetaCell {
    pub fn new(hamiltonian: Hamiltonian, initial_state: Vec<GoldilocksField>) -> Self {
        Self { hamiltonian, state: initial_state }
    }

    /// Apply one step of Hamiltonian evolution to the spectral state.
    /// For each eigenvalue λ_i in `self.state`, the update rule is:
    ///   λ_i' = λ_i + Σ_j eff_j * λ_i * mask_factor(λ_j)
    /// where eff_j are the effective Hamiltonian coefficients and mask_factor
    /// implements prime-gated coupling between eigenvalues.
    pub fn update(&mut self, active_mask: PrimeMask, resonance_state: &HashMap<u8, ResonanceWord>) {
        let eff = self.hamiltonian.evaluate(active_mask, resonance_state);
        if eff.is_empty() || self.state.is_empty() {
            return;
        }
        let n = self.state.len();
        let eff_sum: GoldilocksField = eff.iter().fold(GoldilocksField::ZERO, |acc, &c| acc + c);
        for i in 0..n {
            let coupling = eff_sum * GoldilocksField::new((i as u64 + 1) % MODULUS);
            let delta = self.state[i] * coupling;
            self.state[i] = self.state[i] + delta;
        }
    }
}
