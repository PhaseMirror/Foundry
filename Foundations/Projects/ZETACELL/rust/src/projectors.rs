//! Constitutional & Ethical Projectors on Dual-Sector Space

use crate::state::ZetaState;

pub struct ProjectorEngine;

impl ProjectorEngine {
    /// Constitutional Projector Π_CSL: Row-wise norm capping & soft quantile thresholding
    pub fn csl_project(state: &mut ZetaState, safety_clip: f64, sparsity_q: f64) {
        // 1. Prime sector row-wise norm clamping
        for i in 0..state.n_p {
            let row_start = i * state.n_f;
            let row_end = row_start + state.n_f;
            let row = &mut state.psi[row_start..row_end];
            let norm = row.iter().map(|&x| x * x).sum::<f64>().sqrt().max(1e-8);
            if norm > safety_clip {
                let scale = safety_clip / norm;
                for x in row.iter_mut() {
                    *x *= scale;
                }
            }
        }

        // 2. Zero sector row-wise norm clamping
        for k in 0..state.n_z {
            let row_start = k * state.n_g;
            let row_end = row_start + state.n_g;
            let row = &mut state.chi[row_start..row_end];
            let norm = row.iter().map(|&x| x * x).sum::<f64>().sqrt().max(1e-8);
            if norm > safety_clip {
                let scale = safety_clip / norm;
                for x in row.iter_mut() {
                    *x *= scale;
                }
            }
        }

        // 3. Sparsity thresholding
        if sparsity_q > 0.0 {
            for x in state.psi.iter_mut() {
                if x.abs() < sparsity_q {
                    *x = 0.0;
                }
            }
            for x in state.chi.iter_mut() {
                if x.abs() < sparsity_q {
                    *x = 0.0;
                }
            }
        }
    }

    /// Ethical Projector P_E: Channel entropy promotion and non-expansive temperature-modulated soft weighting
    pub fn ethical_project(state: &mut ZetaState, diversity_target: f64) -> (f64, f64) {
        // 1. Prime channel energies
        let mut prime_energies = Vec::with_capacity(state.n_p);
        for i in 0..state.n_p {
            let row_start = i * state.n_f;
            let norm = state.psi[row_start..row_start + state.n_f]
                .iter()
                .map(|&x| x * x)
                .sum::<f64>()
                .sqrt()
                .max(1e-8);
            prime_energies.push(norm);
        }

        // 2. Zero channel energies
        let mut zero_energies = Vec::with_capacity(state.n_z);
        for k in 0..state.n_z {
            let row_start = k * state.n_g;
            let norm = state.chi[row_start..row_start + state.n_g]
                .iter()
                .map(|&x| x * x)
                .sum::<f64>()
                .sqrt()
                .max(1e-8);
            zero_energies.push(norm);
        }

        // Compute normalized distributions & Shannon entropies
        let total_ep: f64 = prime_energies.iter().sum();
        let total_ez: f64 = zero_energies.iter().sum();

        let mut hp = 0.0;
        for &e in &prime_energies {
            let p = e / total_ep;
            hp -= p * p.ln();
        }

        let mut hz = 0.0;
        for &e in &zero_energies {
            let p = e / total_ez;
            hz -= p * p.ln();
        }

        // Diversity gaps
        let gap_p = (diversity_target - hp).max(0.0);
        let gap_z = (diversity_target - hz).max(0.0);

        let tau_p = 1.0 + gap_p;
        let tau_z = 1.0 + gap_z;

        // Apply non-expansive soft weights
        let mut wp = Vec::with_capacity(state.n_p);
        for &e in &prime_energies {
            wp.push((e / tau_p).exp());
        }
        let sum_wp: f64 = wp.iter().sum();
        for i in 0..state.n_p {
            let factor = wp[i] / sum_wp;
            let row_start = i * state.n_f;
            for x in &mut state.psi[row_start..row_start + state.n_f] {
                *x *= factor.min(1.0);
            }
        }

        let mut wz = Vec::with_capacity(state.n_z);
        for &e in &zero_energies {
            wz.push((e / tau_z).exp());
        }
        let sum_wz: f64 = wz.iter().sum();
        for k in 0..state.n_z {
            let factor = wz[k] / sum_wz;
            let row_start = k * state.n_g;
            for x in &mut state.chi[row_start..row_start + state.n_g] {
                *x *= factor.min(1.0);
            }
        }

        (hp, hz)
    }
}
