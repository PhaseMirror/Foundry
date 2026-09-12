//! Dual-Sector State Space H_ζ = H_p ⊕ H_z

use serde::{Deserialize, Serialize};

/// Dual-Sector ZetaCell State: Ψ = (ψ, χ)
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ZetaState {
    pub n_p: usize,
    pub n_f: usize,
    pub n_z: usize,
    pub n_g: usize,
    /// Prime sector state ψ ∈ R^{n_p × n_f} (row-major)
    pub psi: Vec<f64>,
    /// Zeta-zero witness state χ ∈ R^{n_z × n_g} (row-major)
    pub chi: Vec<f64>,
}

impl ZetaState {
    pub fn new(n_p: usize, n_f: usize, n_z: usize, n_g: usize) -> Self {
        Self {
            n_p,
            n_f,
            n_z,
            n_g,
            psi: vec![0.0; n_p * n_f],
            chi: vec![0.0; n_z * n_g],
        }
    }

    pub fn from_data(n_p: usize, n_f: usize, n_z: usize, n_g: usize, psi: Vec<f64>, chi: Vec<f64>) -> Self {
        assert_eq!(psi.len(), n_p * n_f);
        assert_eq!(chi.len(), n_z * n_g);
        Self {
            n_p,
            n_f,
            n_z,
            n_g,
            psi,
            chi,
        }
    }

    /// Compute Frobenius norm squared of prime sector: ||ψ||_F^2
    pub fn norm_sq_psi(&self) -> f64 {
        self.psi.iter().map(|&x| x * x).sum()
    }

    /// Compute Frobenius norm squared of zero sector: ||χ||_F^2
    pub fn norm_sq_chi(&self) -> f64 {
        self.chi.iter().map(|&x| x * x).sum()
    }

    /// Total product norm: ||Ψ|| = sqrt(||ψ||_F^2 + ||χ||_F^2)
    pub fn norm(&self) -> f64 {
        (self.norm_sq_psi() + self.norm_sq_chi()).sqrt()
    }

    /// Compute Euclidean / Frobenius distance to another state: ||Ψ - Φ||
    pub fn distance(&self, other: &Self) -> f64 {
        assert_eq!(self.n_p, other.n_p);
        assert_eq!(self.n_f, other.n_f);
        assert_eq!(self.n_z, other.n_z);
        assert_eq!(self.n_g, other.n_g);

        let d_psi: f64 = self
            .psi
            .iter()
            .zip(&other.psi)
            .map(|(&a, &b)| (a - b) * (a - b))
            .sum();

        let d_chi: f64 = self
            .chi
            .iter()
            .zip(&other.chi)
            .map(|(&a, &b)| (a - b) * (a - b))
            .sum();

        (d_psi + d_chi).sqrt()
    }
}
