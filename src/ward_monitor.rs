use nalgebra::DVector;
use crate::telemetry::TelemetryBus;

/// Calculates the Kullback-Leibler (KL) divergence of the current state distribution
/// against the lawful reference manifold.
pub fn compute_kl_divergence(p: &DVector<f64>, q: &DVector<f64>) -> f64 {
    assert_eq!(p.len(), q.len(), "KL-divergence dimensions must match");
    let mut sum = 0.0;
    
    // Normalize vectors to represent valid probability distributions
    let p_sum: f64 = p.iter().map(|x| x.abs()).sum();
    let q_sum: f64 = q.iter().map(|x| x.abs()).sum();
    
    let p_norm = if p_sum > 1e-15 { p.map(|x| x.abs() / p_sum) } else { DVector::from_element(p.len(), 1.0 / p.len() as f64) };
    let q_norm = if q_sum > 1e-15 { q.map(|x| x.abs() / q_sum) } else { DVector::from_element(q.len(), 1.0 / q.len() as f64) };

    for i in 0..p_norm.len() {
        let p_val = p_norm[i];
        let q_val = q_norm[i];
        if p_val > 1e-15 {
            let ratio = p_val / (q_val + 1e-15);
            sum += p_val * ratio.ln();
        }
    }
    sum
}

/// The WardMonitor sidecar process/component.
/// It monitors KL-divergence of the manifold state in real-time,
/// providing proactive drift detection.
pub struct WardMonitor {
    pub reference_manifold: DVector<f64>,
    pub warning_threshold: f64,
    pub critical_threshold: f64,
}

impl WardMonitor {
    pub fn new(reference_manifold: DVector<f64>, warning_threshold: f64, critical_threshold: f64) -> Self {
        Self {
            reference_manifold,
            warning_threshold,
            critical_threshold,
        }
    }

    /// Evaluates the current state vector against the reference manifold.
    /// Emits telemetry alerts and returns the calculated dissonance score (rho).
    /// If rho exceeds the critical threshold, returns an Err representing a system FREEZE.
    pub fn evaluate_state(&self, x: &DVector<f64>, telemetry: &TelemetryBus, step_index: usize) -> Result<f64, String> {
        let rho = compute_kl_divergence(x, &self.reference_manifold);

        if rho >= self.critical_threshold {
            telemetry.emit_alert("CRITICAL_DISSONANCE_BREACH", serde_json::json!({
                "step_index": step_index,
                "dissonance_rho": rho,
                "threshold": self.critical_threshold,
                "action": "FREEZE"
            }));
            return Err(format!(
                "CRITICAL: Dissonance score rho={:.4} exceeded critical threshold={:.4}. System entering FREEZE state.",
                rho, self.critical_threshold
            ));
        } else if rho >= self.warning_threshold {
            telemetry.emit_alert("WARNING_DISSONANCE_DRIFT", serde_json::json!({
                "step_index": step_index,
                "dissonance_rho": rho,
                "threshold": self.warning_threshold,
                "action": "WARN"
            }));
        }

        Ok(rho)
    }
}

pub type Tensor = nalgebra::DVector<f64>;

pub struct FZSKernel;

impl FZSKernel {
    pub fn compute_kl_divergence(current_state: &Tensor, reference: &Tensor) -> f64 {
        super::compute_kl_divergence(current_state, reference)
    }
}
