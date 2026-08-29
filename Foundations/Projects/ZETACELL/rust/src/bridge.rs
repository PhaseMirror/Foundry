//! Prime-Zero Bridge Operator & Explicit Formula Kernel

use serde::{Deserialize, Serialize};

/// Canonical First 30 Nontrivial Riemann Zeta Zero Heights (γ_k)
pub const RIEMANN_ZEROS: [f64; 30] = [
    14.1347251417, 21.0220396388, 25.0108575801, 30.4248761259, 32.9350615877,
    37.5861781588, 40.9187190121, 43.3270732809, 48.0051508812, 49.7738324777,
    52.9703214777, 56.4462476971, 59.3470440026, 60.8317785246, 65.1125440481,
    67.0798105295, 69.5464017112, 72.0671576745, 75.7046906991, 77.1448400689,
    79.3373750202, 82.9103808541, 84.7354929805, 87.4252746131, 88.8091112076,
    92.4918992706, 94.6513440405, 95.8706342782, 98.8311942182, 101.317851006,
];

/// Canonical First 30 Primes (p_i)
pub const PRIMES: [u64; 30] = [
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47,
    53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113,
];

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BridgeKernel {
    pub n_p: usize,
    pub n_z: usize,
    /// Kernel matrix K_{ik} ∈ R^{n_p × n_z}
    pub k_matrix: Vec<f64>,
}

impl BridgeKernel {
    /// Construct explicit-formula kernel: K_{ik} = A_{ik} cos(γ_k log p_i) + B_{ik} sin(γ_k log p_i)
    pub fn new_explicit(n_p: usize, n_z: usize, zeros: &[f64], primes: &[u64]) -> Self {
        let mut k_matrix = vec![0.0; n_p * n_z];
        for i in 0..n_p {
            let log_p = (primes[i] as f64).ln();
            for k in 0..n_z {
                let gamma = zeros[k];
                let phase = gamma * log_p;
                // Baseline weights A=1.0, B=0.0 (or normalized by sqrt(n_p * n_z))
                let val = phase.cos() / (n_p as f64).sqrt();
                k_matrix[i * n_z + k] = val;
            }
        }
        Self { n_p, n_z, k_matrix }
    }

    /// Forward pass C_{p->z}(ψ): R^{n_p × n_f} -> R^{n_z × n_g}
    pub fn forward_pz(&self, psi: &[f64], n_f: usize, n_g: usize) -> Vec<f64> {
        let mut chi_out = vec![0.0; self.n_z * n_g];
        for k in 0..self.n_z {
            for i in 0..self.n_p {
                let k_ik = self.k_matrix[i * self.n_z + k];
                for f in 0..n_f.min(n_g) {
                    chi_out[k * n_g + f] += k_ik * psi[i * n_f + f];
                }
            }
        }
        chi_out
    }

    /// Forward pass C_{z->p}(χ): R^{n_z × n_g} -> R^{n_p × n_f}
    pub fn forward_zp(&self, chi: &[f64], n_f: usize, n_g: usize) -> Vec<f64> {
        let mut psi_out = vec![0.0; self.n_p * n_f];
        for i in 0..self.n_p {
            for k in 0..self.n_z {
                let k_ik = self.k_matrix[i * self.n_z + k];
                for f in 0..n_f.min(n_g) {
                    psi_out[i * n_f + f] += k_ik * chi[k * n_g + f];
                }
            }
        }
        psi_out
    }
}
