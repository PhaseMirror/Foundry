use nalgebra::{DMatrix, DVector, Complex, ComplexField};
use serde::{Deserialize, Serialize};

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

    pub fn govern(&mut self, t_op: fn(&DVector<f64>) -> DVector<f64>) -> (f64, f64, SpectralReport) {
        let report = self.analyze(t_op);
        (report.recommended_epsilon, report.op_norm_estimate, report)
    }

    pub fn clear_history(&mut self) {
        self.history.clear();
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
        let contraction_rate = self.history.iter().filter(|r| r.contraction_feasible).count() as f64 / self.history.len() as f64;

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
