use ndarray::{Array2, ArrayViewMut2};

/// Manages recursive update dynamics using entropy gradients and trace-preserving normalizations.
/// 
/// Parity with: drmm/src/feedback_loops.py -> EntropicFeedbackLoop
pub struct EntropicFeedbackLoop {
    pub alpha: f64,
}

impl EntropicFeedbackLoop {
    pub fn new(alpha: f64) -> Self {
        Self { alpha }
    }

    /// Compute entropy gradient ∇S(X) ≈ -log(|X| + ε).
    pub fn entropy_gradient(&self, x: &Array2<f64>) -> Array2<f64> {
        let epsilon = 1e-8;
        x.mapv(|val| -(val.abs() + epsilon).ln())
    }

    /// Apply entropy-damped update to tensor X at time t.
    pub fn update(&self, x: &mut Array2<f64>, t: f64) {
        let grad = self.entropy_gradient(x);
        for (val, g) in x.iter_mut().zip(grad.iter()) {
            *val += self.alpha * t * g;
        }
    }
}

/// Regulates recursive flow convergence under DRMM dynamic rules.
/// 
/// Parity with: drmm/src/feedback_loops.py -> ConvergenceController
pub struct ConvergenceController {
    pub threshold: f64,
}

impl ConvergenceController {
    pub fn new(threshold: f64) -> Self {
        Self { threshold }
    }

    /// Check if system has converged between steps using Frobenius norm.
    pub fn is_converged(&self, x_old: &Array2<f64>, x_new: &Array2<f64>) -> bool {
        let diff = x_new - x_old;
        let mut square_sum = 0.0;
        for val in diff.iter() {
            square_sum += val * val;
        }
        let norm = square_sum.sqrt();
        norm < self.threshold
    }
}

/// Embeds ethical phase-space filters to dampen recursive overload or divergence.
/// 
/// Parity with: drmm/src/feedback_loops.py -> EthicalModulator
pub struct EthicalModulator {
    pub filter_strength: f64,
}

impl EthicalModulator {
    pub fn new(filter_strength: f64) -> Self {
        Self { filter_strength }
    }

    /// Modulate tensor dynamics ethically via nonlinear saturation (tanh).
    pub fn apply(&self, x: &mut Array2<f64>) {
        let x_clone = x.clone();
        for (val, old_val) in x.iter_mut().zip(x_clone.iter()) {
            *val = *old_val - self.filter_strength * old_val.tanh();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_entropic_feedback_parity() {
        let mut x = Array2::from_elem((2, 2), 0.5);
        let loop_ctrl = EntropicFeedbackLoop::new(0.05);
        loop_ctrl.update(&mut x, 1.0);
        
        // gradient = -ln(0.5 + 1e-8) approx 0.693
        // update = 0.5 + 0.05 * 1.0 * 0.693 approx 0.5346
        assert!(x[[0, 0]] > 0.5);
        assert!((x[[0, 0]] - 0.5346).abs() < 1e-3);
    }

    #[test]
    fn test_ethical_modulator_parity() {
        let mut x = Array2::from_elem((2, 2), 1.0);
        let mod_ctrl = EthicalModulator::new(0.1);
        mod_ctrl.apply(&mut x);
        
        // 1.0 - 0.1 * tanh(1.0) approx 1.0 - 0.1 * 0.761 = 0.9239
        assert!(x[[0, 0]] < 1.0);
        assert!((x[[0, 0]] - 0.9239).abs() < 1e-3);
    }

    #[test]
    fn test_convergence_controller() {
        let x1 = Array2::from_elem((2, 2), 1.0);
        let x2 = Array2::from_elem((2, 2), 1.0001);
        let controller = ConvergenceController::new(1e-3);
        
        // diff = 0.0001, norm = sqrt(4 * 0.0001^2) = 0.0002
        assert!(controller.is_converged(&x1, &x2));
    }
}
