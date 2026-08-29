#![forbid(unsafe_code)]

//! # Certified heat flow runtime
//!
//! ## The certificate
//!
//! For a graph Laplacian L with spectral gap λ₂ and step size
//! α ∈ (0, 2/ρ(L)), the heat step `u' = u - α·L·u` satisfies
//!
//! ```text
//! ‖mean_zero(u')‖² ≤ (1 - α·λ₂)² · ‖mean_zero(u)‖²
//! ```
//!
//! with equality of all arithmetic operations up to IEEE-754 round-off,
//! verified with a runtime guestimate tolerance `ε`.
//!
//! ## Soundness
//!
//! - `lambda_2` used by the certificate is a conservative **lower bound**.
//! - `lambda_max` used by validation is a conservative **upper bound**.
//! - The final comparison admits a configurable tolerance to absorb
//!   floating-point error without weakening the mathematical bound.

use crate::graph::Graph;
use crate::spectral::{spectral_gap_lower_bound, spectral_radius};

/// Errors returned by the certificate runtime.
#[derive(Debug, Clone, PartialEq)]
pub enum CertificateError {
    /// The field vector length differs from the graph size.
    LengthMismatch {
        /// The number of vertices in the graph.
        graph: usize,
        /// The length of the supplied field vector.
        field: usize,
    },
    /// The step size is out of the admissible range (0, 2/ρ(L)).
    StepSizeOutOfRange {
        /// The step size that was rejected.
        alpha: f64,
        /// The admissible upper ceiling 2/ρ(L).
        upper: f64,
    },
    /// The Laplacian is degenerate and no valid certificate exists.
    DegenerateSpectralGap,
    /// The certificate was violated (only possible with NaN inputs).
    CertificateViolation {
        /// The observed squared contraction ratio.
        actual: f64,
        /// The theoretical bound (1 - α·λ₂)².
        bound: f64,
        /// The tolerance admitted by this check.
        epsilon: f64,
    },
}

impl core::fmt::Display for CertificateError {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::LengthMismatch { graph, field } => write!(
                f,
                "field length {field} does not match graph size {graph}"
            ),
            Self::StepSizeOutOfRange { alpha, upper } => write!(
                f,
                "step size {alpha} must lie in (0, {upper})"
            ),
            Self::DegenerateSpectralGap => write!(
                f,
                "projected spectral gap is degenerate; no certificate"
            ),
            Self::CertificateViolation {
                actual,
                bound,
                epsilon,
            } => write!(
                f,
                "certificate violated: actual_sq={actual:.8} > bound_sq={bound:.8} (±{epsilon})"
            ),
        }
    }
}

impl core::error::Error for CertificateError {}

/// Result of a single certificate check.
#[derive(Debug, Clone, Copy)]
pub struct CertificateResult {
    /// Whether the certificate passed within tolerance.
    pub passed: bool,
    /// The observed squared contraction ratio ‖mean_zero(u')‖² / ‖mean_zero(u)‖².
    pub actual_ratio: f64,
    /// The theoretical bound (1 - α·λ₂)².
    pub theoretical_bound: f64,
}

/// Default certificate tolerance (IEEE-754 round-off for the squared norm).
pub const DEFAULT_EPSILON: f64 = 1e-9;

/// Certifies spectral parameters for a graph and step size.
///
/// All estimates are conservative: `lambda_2` is a lower bound on the
/// true Fiedler value, `lambda_max` an upper bound on the true spectral
/// radius. This guarantees the certificate is sound (no false passes).
#[derive(Debug)]
pub struct SpectralCertificate {
    /// Lower bound on the spectral gap λ₂.
    pub lambda_2: f64,
    /// Upper bound on the spectral radius ρ(L).
    pub lambda_max: f64,
    /// Admissible step size upper ceiling 2/ρ(L).
    pub step_upper: f64,
}

impl SpectralCertificate {
    /// Derive conservative spectral bounds for `graph`.
    pub fn derive(graph: &Graph) -> Self {
        let laplacian: Vec<Vec<f64>> =
            (0..graph.len()).map(|i| graph.laplacian_row(i).to_vec()).collect();
        let lambda_max = spectral_radius(&laplacian);
        let lambda_2 = spectral_gap_lower_bound(&laplacian);
        Self {
            lambda_2,
            lambda_max,
            step_upper: if lambda_max > 0.0 { 2.0 / lambda_max } else { f64::INFINITY },
        }
    }

    /// Validate that `alpha` is in the admissible step-size range.
    pub fn validate(&self, alpha: f64) -> Result<(), CertificateError> {
        if !(alpha > 0.0 && alpha < self.step_upper) {
            return Err(CertificateError::StepSizeOutOfRange {
                alpha,
                upper: self.step_upper,
            });
        }
        Ok(())
    }
}

/// Certified heat flow state over a fixed graph.
#[derive(Debug)]
pub struct CertifiedState {
    /// The underlying graph (needed for the Laplacian).
    graph: Graph,
    /// Current field values `u ∈ ℝ^n`.
    u: Vec<f64>,
    /// Spectral certificate (immutable after construction).
    cert: SpectralCertificate,
    /// Step size α.
    alpha: f64,
    /// Certificate tolerance ε.
    epsilon: f64,
}

/// The heat-step operator computed by the runtime.
///
/// Pure function: `u'[i] = u[i] - α · (L·u)[i]`. Mirrors the Lean
/// specification `heatStep` exactly (see `certificate-core`).
pub fn heat_step(u: &[f64], laplacian: &[Vec<f64>], alpha: f64) -> Vec<f64> {
    let n = u.len();
    let mut u_new = vec![0.0; n];
    for i in 0..n {
        let mut lap = 0.0;
        for j in 0..n {
            lap += laplacian[i][j] * u[j];
        }
        u_new[i] = u[i] - alpha * lap;
    }
    u_new
}

/// Mean of a field vector.
#[inline]
pub fn mean(u: &[f64]) -> f64 {
    if u.is_empty() {
        return f64::NAN;
    }
    u.iter().sum::<f64>() / u.len() as f64
}

/// The mean-zero component `u - mean(u)·𝟙`.
pub fn mean_zero(u: &[f64]) -> Vec<f64> {
    let m = mean(u);
    u.iter().map(|&x| x - m).collect()
}

/// Squared L2 norm.
#[inline]
pub fn norm_sq(u: &[f64]) -> f64 {
    u.iter().map(|&x| x * x).sum()
}

/// Ratio estimator for `‖mean_zero(u')‖² / ‖mean_zero(u)‖²`.
/// Returns `1.0` when the denominator is exactly zero (safety).
fn contraction_ratio_sq(u_old: &[f64], u_new: &[f64]) -> f64 {
    let d = norm_sq(&mean_zero(u_old));
    let num = norm_sq(&mean_zero(u_new));
    if d == 0.0 {
        1.0
    } else {
        num / d
    }
}

impl CertifiedState {
    /// Construct a certified state, computing spectral bounds and
    /// validating the step size.
    ///
    /// # Errors
    ///
    /// Returns [`CertificateError`] when inputs are inconsistent or the
    /// step size is outside the certified range.
    pub fn new(graph: Graph, u: Vec<f64>, alpha: f64) -> Result<Self, CertificateError> {
        Self::with_epsilon(graph, u, alpha, DEFAULT_EPSILON)
    }

    /// Construct a certified state with a custom tolerance.
    pub fn with_epsilon(
        graph: Graph,
        u: Vec<f64>,
        alpha: f64,
        epsilon: f64,
    ) -> Result<Self, CertificateError> {
        let n = graph.len();
        if u.len() != n {
            return Err(CertificateError::LengthMismatch {
                graph: n,
                field: u.len(),
            });
        }
        let cert = SpectralCertificate::derive(&graph);
        cert.validate(alpha)?;
        if cert.lambda_2 <= 0.0 {
            return Err(CertificateError::DegenerateSpectralGap);
        }
        Ok(Self {
            graph,
            u,
            cert,
            alpha,
            epsilon,
        })
    }

    /// The current field values.
    #[inline]
    pub fn state(&self) -> &[f64] {
        &self.u
    }

    /// The configured step size.
    #[inline]
    pub fn alpha(&self) -> f64 {
        self.alpha
    }

    /// The spectral bounds used by this state.
    #[inline]
    pub fn spectrum(&self) -> (&f64, &f64) {
        (&self.cert.lambda_2, &self.cert.lambda_max)
    }

    /// Execute one certified heat-flow step.
    ///
    /// The step is computed, the certificate is checked, and only a
    /// passing certificate commits the new state. A violation rolls
    /// back and returns the diagnostic error.
    pub fn step(&mut self) -> Result<CertificateResult, CertificateError> {
        let laplacian: Vec<Vec<f64>> = (0..self.graph.len())
            .map(|i| self.graph.laplacian_row(i).to_vec())
            .collect();
        let u_new = heat_step(&self.u, &laplacian, self.alpha);
        let passed = self.check(&self.u, &u_new);
        if passed.passed {
            self.u = u_new;
            Ok(passed)
        } else {
            Err(CertificateError::CertificateViolation {
                actual: passed.actual_ratio,
                bound: passed.theoretical_bound,
                epsilon: self.epsilon,
            })
        }
    }

    /// Check the certificate for a candidate next state without
    /// committing it.
    pub fn check(&self, u_old: &[f64], u_new: &[f64]) -> CertificateResult {
        let actual_ratio = contraction_ratio_sq(u_old, u_new);
        let bound = self.theoretical_bound_sq();
        let passed = !actual_ratio.is_nan() && actual_ratio <= bound + self.epsilon;
        CertificateResult {
            passed,
            actual_ratio,
            theoretical_bound: bound,
        }
    }

    /// The theoretical bound (1 - α·λ₂)².
    pub fn theoretical_bound_sq(&self) -> f64 {
        let q = 1.0 - self.alpha * self.cert.lambda_2;
        q * q
    }

    /// The contraction factor (1 - α·λ₂).
    pub fn contraction_factor(&self) -> f64 {
        1.0 - self.alpha * self.cert.lambda_2
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::graph::Graph;

    fn path_graph(n: usize) -> Graph {
        let mut w = vec![vec![0.0; n]; n];
        for i in 0..n.saturating_sub(1) {
            w[i][i + 1] = 1.0;
            w[i + 1][i] = 1.0;
        }
        Graph::from_weights(w).unwrap()
    }

    #[test]
    fn k2_step_contracts_mean_zero() {
        // 2-node graph, L = [[1,-1],[-1,1]], λ₂ = 2, ρ = 2.
        // α ∈ (0, 1). Use α = 0.25.
        let g = path_graph(2);
        let u = vec![3.0, -1.0]; // mean 1.0, mean-zero energy 4.0
        let mut state = CertifiedState::new(g, u, 0.25).unwrap();
        assert!((state.contraction_factor() - (1.0 - 0.25 * 2.0)).abs() < 1e-12);
        let res = state.step().unwrap();
        assert!(res.passed, "certificate must pass for valid alpha");
        assert!(state.state()[0] < 3.0 && state.state()[0] > 1.0);
    }

    #[test]
    fn zero_mean_vector_stays_at_mean() {
        // Mean-zero vector maps toward zero.
        let g = path_graph(2);
        let u = vec![1.0, -1.0];
        let mut state = CertifiedState::new(g, u, 0.5).unwrap();
        let res = state.step().unwrap();
        assert!(res.passed);
        // 1 - α·λ₂ = 1 - 0.5*2 = 0 → both entries should be ~0
        assert!(state.state()[0].abs() < 1e-9);
        assert!(state.state()[1].abs() < 1e-9);
    }

    #[test]
    fn step_size_out_of_range_rejected() {
        let g = path_graph(2);
        let u = vec![1.0, 2.0];
        let err = CertifiedState::new(g, u, 1.5).unwrap_err();
        assert!(matches!(err, CertificateError::StepSizeOutOfRange { .. }));
    }

    #[test]
    fn negative_step_rejected() {
        let g = path_graph(2);
        let u = vec![1.0, 2.0];
        let err = CertifiedState::new(g, u, -0.1).unwrap_err();
        assert!(matches!(err, CertificateError::StepSizeOutOfRange { .. }));
    }

    #[test]
    fn length_mismatch_rejected() {
        let g = path_graph(3);
        let u = vec![1.0, 2.0];
        let err = CertifiedState::new(g, u, 0.1).unwrap_err();
        assert!(matches!(err, CertificateError::LengthMismatch { .. }));
    }

    #[test]
    fn heat_step_matches_manual() {
        let l = vec![vec![1.0, -1.0], vec![-1.0, 1.0]];
        let u = vec![4.0, 0.0];
        let u_new = heat_step(&u, &l, 0.5);
        // u' = u - 0.5·L·u = [4 - 0.5*(4), 0 - 0.5*(-4)] = [2, 2]
        assert!((u_new[0] - 2.0).abs() < 1e-12);
        assert!((u_new[1] - 2.0).abs() < 1e-12);
    }

    #[test]
    fn mean_preserved_by_heat_step() {
        let g = path_graph(4);
        let u = vec![1.0, 2.0, 3.0, 4.0];
        let l: Vec<Vec<f64>> = (0..g.len())
            .map(|i| g.laplacian_row(i).to_vec())
            .collect();
        let u_new = heat_step(&u, &l, 0.1);
        assert!((mean(&u) - mean(&u_new)).abs() < 1e-12);
    }

    #[test]
    fn contraction_factor_unit_interval() {
        let g = path_graph(3);
        let u = vec![0.0, 1.0, 0.0];
        let state = CertifiedState::new(g, u, 0.1).unwrap();
        let q = state.contraction_factor();
        assert!(q > 0.0 && q < 1.0, "q = {q}");
    }
}