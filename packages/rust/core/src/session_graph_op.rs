use crate::spectral::{SpectralGovernor, SpectralMetrics};
use crate::types::PirtmModulus;

/// Session graph operation with embedded spectral L0 contractivity
///
/// Captures the gain matrix, spectral metrics, and tier for tensor network lowering.
/// Used for Phase 3 HITL governance integration.
#[derive(Debug, Clone)]
pub struct SessionGraphOp {
    pub prime_index: u64,
    pub gain_matrix: Vec<Vec<f64>>,
    pub modulus: PirtmModulus,
    pub tier: usize,
    pub spectral_metrics: SpectralMetrics,
}

impl SessionGraphOp {
    /// Create a session graph with unresolved coupling (stub state).
    /// Used before gain matrix resolution.
    pub fn unresolved(prime_index: u64, modulus: PirtmModulus) -> Self {
        Self {
            prime_index,
            gain_matrix: vec![],
            modulus,
            tier: 2,
            spectral_metrics: SpectralMetrics::default(),
        }
    }

    /// Create a session graph with spectral metrics computed.
    /// This is the primary constructor for Phase 3 governed execution.
    pub fn with_spectral(
        prime_index: u64,
        gain_matrix: Vec<Vec<f64>>,
        modulus: PirtmModulus,
        tier: usize,
    ) -> Result<Self, String> {
        let metrics = SpectralGovernor::evaluate_stability(&gain_matrix, tier)
            .map_err(|e| format!("Spectral analysis failed: {}", e))?;

        Ok(Self {
            prime_index,
            gain_matrix,
            modulus,
            tier,
            spectral_metrics: metrics,
        })
    }

    /// Get the spectral radius from computed metrics.
    pub fn spectral_radius(&self) -> f64 {
        self.spectral_metrics.spectral_radius
    }

    /// Get the contraction margin (1 - ρ).
    pub fn contraction_margin(&self) -> f64 {
        self.spectral_metrics.contraction_margin
    }

    /// Check if the session graph is spectrally stable for its tier.
    pub fn is_stable(&self) -> bool {
        let epsilon = match self.tier {
            1 => 0.10,
            2 => 0.05,
            3 => 0.02,
            4 => 0.01,
            _ => 0.05,
        };
        self.spectral_metrics.spectral_radius < 1.0 - epsilon
    }

    /// Emit MLIR session_graph operation with embedded spectral metrics.
    pub fn emit_mlir(&self) -> Result<String, String> {
        let gain_attr = format!("#pirtm.resolved_coupling(dim={})", self.gain_matrix.len());
        let radius_str = format!("{:.4}", self.spectral_metrics.spectral_radius);
        let margin_str = format!("{:.4}", self.spectral_metrics.contraction_margin);
        let convergence_str = format!("{:.4}", self.spectral_metrics.convergence_rate);
        let iters_str = format!("{}", self.spectral_metrics.effective_iterations);

        Ok(format!(
            "  pirtm.session_graph {{ prime_index = {} : i64, gain_matrix = {}, spectral_radius = {} : f64, stability_margin = {} : f64, convergence_rate = {} : f64, effective_iterations = {} : i32, tier = {} : i32 }}",
            self.prime_index, gain_attr, radius_str, margin_str, convergence_str, iters_str, self.tier
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_session_graph_op_unresolved() {
        let op = SessionGraphOp::unresolved(7919, PirtmModulus(7919));
        assert_eq!(op.prime_index, 7919);
        assert_eq!(op.tier, 2);
        assert_eq!(op.gain_matrix.len(), 0);
    }

    #[test]
    fn test_session_graph_op_spectrally_governed() {
        let stable_matrix = vec![vec![0.3, 0.1], vec![0.1, 0.3]];
        let op = SessionGraphOp::with_spectral(7919, stable_matrix, PirtmModulus(7919), 2).unwrap();
        assert!(op.is_stable());
        assert!(op.spectral_radius() < 1.0);
    }

    #[test]
    fn test_session_graph_op_emits_mlir() {
        let stable_matrix = vec![vec![0.3, 0.1], vec![0.1, 0.3]];
        let op = SessionGraphOp::with_spectral(7919, stable_matrix, PirtmModulus(7919), 2).unwrap();
        let mlir = op.emit_mlir().unwrap();
        assert!(mlir.contains("pirtm.session_graph"));
        assert!(mlir.contains("tier = 2"));
    }
}
