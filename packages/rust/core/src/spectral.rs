use nalgebra::{Complex, ComplexField, DMatrix, DVector};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SpectralMetrics {
    pub spectral_radius: f64,
    pub gershgorin_radius: f64,
    pub contraction_margin: f64,
    pub drift_score: f64,
    pub iteration_count: usize,
    pub used_power_iteration: bool,
    pub convergence_rate: f64,
    pub effective_iterations: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GershgorinDisk {
    pub center: f64,
    pub radius: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GershgorinCertificate {
    pub disks: Vec<GershgorinDisk>,
    pub max_radius: f64,
    pub is_stable: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpectralReport {
    pub spectral_radius: f64,
    pub spectral_entropy: f64,
    pub phase_coherence: f64,
    pub op_norm_estimate: f64,
    pub contraction_feasible: bool,
    pub recommended_epsilon: f64,
    pub eigenvalues: Vec<Complex<f64>>,
    pub detail: serde_json::Value,
}

pub fn spectral_decomposition(matrix: &DMatrix<f64>) -> Vec<Complex<f64>> {
    let complex_matrix = matrix.map(|x| Complex::new(x, 0.0));
    let eig = complex_matrix.eigenvalues().unwrap();
    eig.iter().cloned().collect()
}

pub fn spectral_entropy(eigvals: &[Complex<f64>], normalize: bool) -> f64 {
    let mut powers: Vec<f64> = eigvals.iter().map(|c| c.norm_sqr()).collect();
    let total: f64 = powers.iter().sum();
    if normalize && total > 0.0 {
        for p in &mut powers {
            *p /= total;
        }
    }
    let entropy: f64 = -powers.iter().map(|p| p * (p + 1e-12).ln()).sum::<f64>();
    entropy
}

pub fn phase_coherence(eigvals: &[Complex<f64>]) -> f64 {
    if eigvals.is_empty() {
        return 0.0;
    }
    let mut sum_exp = Complex::new(0.0, 0.0);
    for c in eigvals {
        let phase = c.argument();
        sum_exp += Complex::from_polar(1.0, phase);
    }
    let mean_exp = sum_exp / (eigvals.len() as f64);
    1.0 - mean_exp.norm()
}

pub struct SpectralGovernor {
    pub dim: usize,
    pub min_epsilon: f64,
    pub max_epsilon: f64,
    pub safety_margin: f64,
    pub entropy_ceiling: f64,
    history: Vec<SpectralReport>,
}

impl SpectralGovernor {
    pub fn new(dim: usize) -> Self {
        Self {
            dim,
            min_epsilon: 0.01,
            max_epsilon: 0.3,
            safety_margin: 0.1,
            entropy_ceiling: 2.0,
            history: Vec::new(),
        }
    }

    pub fn gershgorin_disks_from_matrix(matrix: &DMatrix<f64>) -> GershgorinCertificate {
        let n = matrix.nrows();
        let mut disks = Vec::with_capacity(n);
        let mut max_radius = 0.0f64;

        for i in 0..n {
            let center = matrix[(i, i)];
            let radius: f64 = (0..n)
                .filter(|&j| j != i)
                .map(|j| matrix[(i, j)].abs())
                .sum();
            disks.push(GershgorinDisk { center, radius });
            max_radius = if radius > max_radius {
                radius
            } else {
                max_radius
            };
        }

        let is_stable = disks.iter().all(|d| (d.center.abs() + d.radius) < 0.99);

        GershgorinCertificate {
            disks,
            max_radius,
            is_stable,
        }
    }

    pub fn gershgorin_disks(matrix: &[Vec<f64>]) -> GershgorinCertificate {
        let n = matrix.len();
        let mut disks = Vec::with_capacity(n);
        let mut max_radius = 0.0f64;

        for i in 0..n {
            let center = matrix[i][i];
            let radius: f64 = matrix[i]
                .iter()
                .enumerate()
                .filter(|(j, _)| *j != i)
                .map(|(_, &val)| val.abs())
                .sum();
            disks.push(GershgorinDisk { center, radius });
            max_radius = if radius > max_radius {
                radius
            } else {
                max_radius
            };
        }

        let is_stable = disks.iter().all(|d| (d.center.abs() + d.radius) < 0.99);

        GershgorinCertificate {
            disks,
            max_radius,
            is_stable,
        }
    }

    pub fn power_iteration(matrix: &[Vec<f64>], max_iter: usize, tol: f64) -> (f64, usize, f64) {
        let n = matrix.len();
        if n == 0 {
            return (0.0, 0, 0.0);
        }

        let mut x: Vec<f64> = (0..n).map(|i| 1.0 / (1.0 + i as f64)).collect();
        let mut lambda = 0.0f64;
        let mut convergence_rate = 0.0f64;

        for iter in 1..=max_iter {
            let mut y = vec![0.0f64; n];
            for i in 0..n {
                for j in 0..n {
                    y[i] += matrix[i][j] * x[j];
                }
            }

            let norm: f64 = y.iter().map(|&yi| yi * yi).sum::<f64>().sqrt();
            let new_lambda = if norm > 1e-12 { norm } else { 0.0 };

            if lambda > 0.0 {
                convergence_rate = (new_lambda - lambda).abs() / lambda;
            }

            if (new_lambda - lambda).abs() < tol {
                return (new_lambda, iter, convergence_rate);
            }

            lambda = new_lambda;
            if norm > 1e-12 {
                for i in 0..n {
                    x[i] = y[i] / norm;
                }
            }
        }

        (lambda, max_iter, convergence_rate)
    }

    pub fn hybrid_spectral_radius(matrix: &[Vec<f64>]) -> SpectralMetrics {
        let cert = Self::gershgorin_disks(matrix);

        if cert.is_stable {
            let upper_bound = cert
                .disks
                .iter()
                .map(|d| d.center.abs() + d.radius)
                .fold(0.0f64, |a, b| if b > a { b } else { a });

            SpectralMetrics {
                spectral_radius: upper_bound,
                gershgorin_radius: cert.max_radius,
                contraction_margin: 1.0 - upper_bound,
                drift_score: upper_bound - cert.max_radius,
                iteration_count: 0,
                used_power_iteration: false,
                convergence_rate: 0.0,
                effective_iterations: 0,
            }
        } else {
            let (rho, iters, rate) = Self::power_iteration(matrix, 100, 1e-6);
            SpectralMetrics {
                spectral_radius: rho,
                gershgorin_radius: cert.max_radius,
                contraction_margin: 1.0 - rho,
                drift_score: rho - cert.max_radius,
                iteration_count: iters,
                used_power_iteration: true,
                convergence_rate: rate,
                effective_iterations: iters,
            }
        }
    }

    pub fn evaluate_stability(matrix: &[Vec<f64>], tier: usize) -> Result<SpectralMetrics, String> {
        let metrics = Self::hybrid_spectral_radius(matrix);

        let epsilon = match tier {
            1 => 0.10,
            2 => 0.05,
            3 => 0.02,
            4 => 0.01,
            _ => 0.05,
        };

        if metrics.spectral_radius >= 1.0 - epsilon {
            return Err(format!(
                "SPECTRAL_VIOLATION: rho={:.4} >= 1 - epsilon={:.2}",
                metrics.spectral_radius, epsilon
            ));
        }

        Ok(metrics)
    }

    pub fn verify_spectral_small_gain(&self, gain_matrix: &DMatrix<f64>) -> Result<f64, String> {
        let complex_matrix = gain_matrix.map(|x| Complex::new(x, 0.0));
        let eigvals = complex_matrix
            .eigenvalues()
            .ok_or("Could not compute eigenvalues of gain matrix")?;
        let spectral_radius = eigvals.iter().map(|c| c.norm()).fold(0.0, f64::max);

        if spectral_radius >= 1.0 {
            Err(format!(
                "Spectral small-gain FAIL: r(Ψ) = {:.4} >= 1.0",
                spectral_radius
            ))
        } else {
            Ok(spectral_radius)
        }
    }

    pub fn verify_mlir_session_graph(&self, gain_matrix_attr: &str) -> Result<f64, String> {
        if gain_matrix_attr == "#pirtm.unresolved_coupling" {
            return Err(
                "Verification FAIL: unresolved coupling sentinel found in session_graph"
                    .to_string(),
            );
        }

        Err(format!("Verification FAIL: Parsing of complex gain matrix attributes not yet implemented in Rust stubs: {}", gain_matrix_attr))
    }

    pub fn analyze(&mut self, t_op: fn(&DVector<f64>) -> DVector<f64>) -> SpectralReport {
        let mut jacobian = DMatrix::zeros(self.dim, self.dim);
        let delta = 1e-5;
        let x0 = DVector::zeros(self.dim);
        let f0 = t_op(&x0);

        for j in 0..self.dim {
            let mut x_j = x0.clone();
            x_j[j] += delta;
            let f_j = t_op(&x_j);
            let col = (f_j - &f0) / delta;
            jacobian.set_column(j, &col);
        }

        let eigvals = spectral_decomposition(&jacobian);
        let spectral_radius = eigvals.iter().map(|c| c.norm()).fold(0.0, f64::max);
        let entropy = spectral_entropy(&eigvals, true);
        let coherence = phase_coherence(&eigvals);

        let svd = jacobian.clone().svd(false, false);
        let op_norm_estimate = svd.singular_values[0];

        let contraction_feasible = spectral_radius < 1.0;
        let recommended_epsilon = if contraction_feasible {
            let candidate = 1.0 - spectral_radius - self.safety_margin;
            candidate.max(self.min_epsilon).min(self.max_epsilon)
        } else {
            self.max_epsilon
        };

        let report = SpectralReport {
            spectral_radius,
            spectral_entropy: entropy,
            phase_coherence: coherence,
            op_norm_estimate,
            contraction_feasible,
            recommended_epsilon,
            eigenvalues: eigvals,
            detail: serde_json::json!({
                "dim": self.dim,
                "jacobian_norm": jacobian.norm(),
                "singular_values": svd.singular_values.as_slice(),
                "entropy_within_ceiling": entropy <= self.entropy_ceiling,
            }),
        };

        self.history.push(report.clone());
        report
    }

    pub fn govern(
        &mut self,
        t_op: fn(&DVector<f64>) -> DVector<f64>,
    ) -> (f64, f64, SpectralReport) {
        let report = self.analyze(t_op);
        (report.recommended_epsilon, report.op_norm_estimate, report)
    }

    pub fn trend(&self) -> serde_json::Value {
        if self.history.is_empty() {
            return serde_json::json!({"reports": 0});
        }

        let radii: Vec<f64> = self.history.iter().map(|r| r.spectral_radius).collect();
        let entropies: Vec<f64> = self.history.iter().map(|r| r.spectral_entropy).collect();

        let radius_min = radii.iter().fold(f64::INFINITY, |a, &b| a.min(b));
        let radius_max = radii.iter().fold(f64::NEG_INFINITY, |a, &b| a.max(b));
        let entropy_mean = entropies.iter().sum::<f64>() / entropies.len() as f64;
        let contraction_rate = self
            .history
            .iter()
            .filter(|r| r.contraction_feasible)
            .count() as f64
            / self.history.len() as f64;

        serde_json::json!({
            "reports": self.history.len(),
            "radius_min": radius_min,
            "radius_max": radius_max,
            "radius_trend": if radius_max - radius_min < 0.05 { "stable" } else { "volatile" },
            "entropy_mean": entropy_mean,
            "contraction_rate": contraction_rate,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gershgorin_stable_matrix() {
        let matrix = vec![vec![0.5, 0.1], vec![0.1, 0.5]];

        let cert = SpectralGovernor::gershgorin_disks(&matrix);
        assert!(cert.is_stable);
        assert!(cert.max_radius > 0.0);
    }

    #[test]
    fn test_gershgorin_unstable_matrix() {
        let matrix = vec![vec![0.9, 0.1], vec![0.1, 0.9]];

        let cert = SpectralGovernor::gershgorin_disks(&matrix);
        assert!(!cert.is_stable);
    }

    #[test]
    fn test_power_iteration() {
        let matrix = vec![vec![1.0, 0.5], vec![0.5, 1.0]];

        let (rho, _, rate) = SpectralGovernor::power_iteration(&matrix, 100, 1e-6);
        assert!((rho - 1.5).abs() < 0.1);
        assert!(rate >= 0.0);
    }

    #[test]
    fn test_convergence_rate_tracked() {
        let unstable_matrix = vec![vec![0.9, 0.1], vec![0.1, 0.9]];

        let metrics = SpectralGovernor::hybrid_spectral_radius(&unstable_matrix);
        assert!(metrics.used_power_iteration);
        assert!(metrics.convergence_rate >= 0.0);
        assert!(metrics.effective_iterations > 0);
    }

    #[test]
    fn test_hybrid_spectral() {
        let stable_matrix = vec![vec![0.3, 0.1], vec![0.1, 0.3]];

        let metrics = SpectralGovernor::hybrid_spectral_radius(&stable_matrix);
        assert!(!metrics.used_power_iteration);
        assert!(metrics.spectral_radius < 1.0);
    }

    #[test]
    fn test_tier_epsilon_margins() {
        let boundary_matrix = vec![vec![0.98, 0.01], vec![0.01, 0.98]];

        let result = SpectralGovernor::evaluate_stability(&boundary_matrix, 1);
        assert!(result.is_err());

        let result = SpectralGovernor::evaluate_stability(&boundary_matrix, 2);
        assert!(result.is_err());

        let result = SpectralGovernor::evaluate_stability(&boundary_matrix, 3);
        assert!(result.is_err());
    }

    #[test]
    fn test_tier_epsilon_margins_pass() {
        let pass_matrix = vec![vec![0.96, 0.01], vec![0.01, 0.96]];

        let result = SpectralGovernor::evaluate_stability(&pass_matrix, 4);
        assert!(result.is_ok());
    }
}
