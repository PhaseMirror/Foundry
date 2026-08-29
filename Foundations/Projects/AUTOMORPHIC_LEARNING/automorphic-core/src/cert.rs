//! Certificates: SoftmaxUB, SlopeUB, unitarity residual, permutation KS.
//!
//! These are the runtime checks that ensure safety and correctness.

use nalgebra::{Complex, DMatrix};
use num_complex::Complex64;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum CertError {
    #[error("unitarity residual {residual} exceeds threshold {threshold}")]
    UnitarityViolation { residual: f64, threshold: f64 },
    #[error("permutation KS {ks} exceeds threshold {threshold}")]
    PermutationKSViolation { ks: f64, threshold: f64 },
    #[error("SlopeUB {slopeub} exceeds ceiling {ceiling}")]
    SlopeUBViolation { slopeub: f64, ceiling: f64 },
}

/// Configuration for runtime certificates.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct CertConfig {
    pub unitarity_threshold: f64,
    pub permutation_ks_threshold: f64,
    pub slopeub_ceiling: f64,
}

impl Default for CertConfig {
    fn default() -> Self {
        Self {
            unitarity_threshold: 1e-8,
            permutation_ks_threshold: 5e-6,
            slopeub_ceiling: 50.0,
        }
    }
}

/// Softmax Jacobian upper bound: $\|J_{\text{softmax}}\|_{1 \to 1} \le \max_i 2 s_i(1-s_i)$.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SoftmaxUB {
    pub value: f64,
    pub probs: Vec<f64>,
}

impl SoftmaxUB {
    /// Compute SoftmaxUB from logits.
    pub fn compute(logits: &[f64]) -> Self {
        let max_logit = logits.iter().fold(f64::NEG_INFINITY, |a, &b| a.max(b));
        let exps: Vec<f64> = logits.iter().map(|&l| (l - max_logit).exp()).collect();
        let sum: f64 = exps.iter().sum();
        let probs: Vec<f64> = exps.iter().map(|&e| e / sum).collect();
        let value = probs
            .iter()
            .map(|&s| 2.0 * s * (1.0 - s))
            .fold(0.0, f64::max);

        Self { value, probs }
    }

    /// Check if the bound is valid (always true by construction).
    pub fn is_valid(&self) -> bool {
        self.value <= 0.5 + 1e-10
    }
}

/// End-to-end $\ell_1$-Lipschitz upper bound.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SlopeUB {
    pub value: f64,
    pub linear_norms: Vec<f64>,
    pub softmax_ubs: Vec<f64>,
}

impl SlopeUB {
    /// Compute SlopeUB from per-layer bounds.
    pub fn compute(linear_norms: &[f64], softmax_ubs: &[f64]) -> Self {
        let mut value = 1.0;
        for &n in linear_norms {
            value *= n;
        }
        for &u in softmax_ubs {
            value *= u;
        }

        Self {
            value,
            linear_norms: linear_norms.to_vec(),
            softmax_ubs: softmax_ubs.to_vec(),
        }
    }

    /// Check if SlopeUB is within the prereg ceiling.
    pub fn passes(&self, ceiling: f64) -> bool {
        self.value <= ceiling
    }
}

/// Unitarity residual certificate.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct UnitarityResidual {
    pub residual: f64,
    pub passes: bool,
}

impl UnitarityResidual {
    /// Compute $\|U^\ast U - I\|_{1 \to 1}$.
    pub fn compute(U: &DMatrix<Complex64>, threshold: f64) -> Self {
        let n = U.nrows();
        let I = DMatrix::<Complex64>::identity(n, n);
        let UU = U.adjoint() * U;
        let diff = &UU - &I;

        // 1→1 norm: max column sum
        let mut max_col_sum: f64 = 0.0;
        for j in 0..n {
            let col_sum: f64 = (0..n).map(|i| diff[(i, j)].norm()).sum();
            max_col_sum = max_col_sum.max(col_sum);
        }

        Self {
            residual: max_col_sum,
            passes: max_col_sum <= threshold,
        }
    }
}

/// Permutation invariance certificate.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct PermutationKS {
    pub ks_spectral: f64,
    pub ks_row_moments: f64,
    pub passes_spectral: bool,
    pub passes_row_moments: bool,
}

impl PermutationKS {
    /// Compute KS statistics for spectral and row-moment invariance.
    pub fn compute(
        phases_a: &[f64],
        phases_b: &[f64],
        moments_a: &[f64],
        moments_b: &[f64],
        threshold: f64,
    ) -> Self {
        let ks_spectral = ks_statistic(phases_a.to_vec(), phases_b.to_vec());
        let ks_row_moments = ks_statistic(moments_a.to_vec(), moments_b.to_vec());

        Self {
            ks_spectral,
            ks_row_moments,
            passes_spectral: ks_spectral <= threshold,
            passes_row_moments: ks_row_moments <= threshold,
        }
    }

    /// Check if both certificates pass.
    pub fn passes(&self) -> bool {
        self.passes_spectral && self.passes_row_moments
    }
}

/// Full certificate bundle for a single batch.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct CertificateBundle {
    pub unitarity: UnitarityResidual,
    pub permutation: PermutationKS,
    pub softmax_ub: SoftmaxUB,
    pub slope_ub: SlopeUB,
    pub all_pass: bool,
}

impl CertificateBundle {
    /// Compute all certificates for a batch.
    pub fn compute(
        U: &DMatrix<Complex64>,
        phases_a: &[f64],
        phases_b: &[f64],
        moments_a: &[f64],
        moments_b: &[f64],
        logits: &[f64],
        linear_norms: &[f64],
        config: &CertConfig,
    ) -> Self {
        let unitarity = UnitarityResidual::compute(U, config.unitarity_threshold);
        let permutation =
            PermutationKS::compute(phases_a, phases_b, moments_a, moments_b, config.permutation_ks_threshold);
        let softmax_ub = SoftmaxUB::compute(logits);
        let slope_ub = SlopeUB::compute(linear_norms, &[softmax_ub.value]);

        let all_pass = unitarity.passes
            && permutation.passes()
            && slope_ub.passes(config.slopeub_ceiling);

        Self {
            unitarity,
            permutation,
            softmax_ub,
            slope_ub,
            all_pass,
        }
    }
}

// KS statistic helper
fn ks_statistic(mut samples_a: Vec<f64>, mut samples_b: Vec<f64>) -> f64 {
    samples_a.sort_by(|a, b| a.partial_cmp(b).unwrap());
    samples_b.sort_by(|a, b| a.partial_cmp(b).unwrap());

    let mut all: Vec<f64> = samples_a.iter().chain(samples_b.iter()).copied().collect();
    all.sort_by(|a, b| a.partial_cmp(b).unwrap());
    all.dedup();

    let ecdf = |x: f64, s: &[f64]| -> f64 {
        let count = s.iter().filter(|&&v| v <= x).count();
        count as f64 / s.len() as f64
    };

    let mut ks: f64 = 0.0;
    for &x in &all {
        let d = (ecdf(x, &samples_a) - ecdf(x, &samples_b)).abs();
        ks = ks.max(d);
    }
    ks
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_softmax_ub_uniform() {
        let logits = vec![0.0; 5];
        let ub = SoftmaxUB::compute(&logits);
        let expected = 2.0 * 0.2 * 0.8;
        assert!((ub.value - expected).abs() < 1e-10);
        assert!(ub.is_valid());
    }

    #[test]
    fn test_softmax_ub_peaked() {
        let logits = vec![10.0, 0.0, 0.0];
        let ub = SoftmaxUB::compute(&logits);
        // Peaked distribution has lower UB
        assert!(ub.value < 0.5);
    }

    #[test]
    fn test_slopeub_basic() {
        let linear_norms = vec![2.0, 3.0];
        let softmax_ubs = vec![0.5];
        let s = SlopeUB::compute(&linear_norms, &softmax_ubs);
        assert!((s.value - 3.0).abs() < 1e-10);
        assert!(s.passes(10.0));
        assert!(!s.passes(2.0));
    }

    #[test]
    fn test_unitarity_residual_identity() {
        let n = 4;
        let I = DMatrix::<Complex64>::identity(n, n);
        let cert = UnitarityResidual::compute(&I, 1e-8);
        assert!(cert.passes);
        assert!(cert.residual < 1e-10);
    }

    #[test]
    fn test_permutation_ks_identical() {
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![1.0, 2.0, 3.0];
        let moments_a = vec![0.5, 1.5];
        let moments_b = vec![0.5, 1.5];
        let cert = PermutationKS::compute(&a, &b, &moments_a, &moments_b, 1e-10);
        assert!(cert.passes());
    }
}
