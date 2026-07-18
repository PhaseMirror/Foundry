use ndarray::Array1;

/// The Multiplicity-Renormalizing Alpha Operator.
///
/// Implements the prime-indexed RG flow on multiplicity profiles using 
/// the exact, tridiagonal Toeplitz diffusion matrix.
pub struct RenormalizationAlpha {
    pub gamma: f64,
    pub beta: f64,
}

impl RenormalizationAlpha {
    /// Instantiate a new Alpha meta-operator.
    pub fn new(gamma: f64, beta: f64) -> Self {
        assert!(gamma >= 0.0, "Gamma (dissipation) must be non-negative");
        assert!(beta >= 0.0, "Beta (coupling) must be non-negative");
        RenormalizationAlpha { gamma, beta }
    }

    /// Determines if the operator sits exactly on the critical manifold.
    /// In physical regimes, `2 * beta == gamma` defines the threshold where 
    /// the fundamental mode is marginally stable (lambda_max = 1).
    pub fn is_critical_manifold(&self) -> bool {
        (2.0 * self.beta - self.gamma).abs() < 1e-9
    }

    /// Classifies the phase.
    pub fn phase(&self) -> &'static str {
        if 2.0 * self.beta < self.gamma - 1e-9 {
            "Filter"
        } else if 2.0 * self.beta > self.gamma + 1e-9 {
            "Runaway"
        } else {
            "Critical"
        }
    }

    /// Applies a single discrete renormalization step across the prime window.
    /// Enforces Dirichlet boundary conditions (v_0 = v_{N+1} = 0).
    pub fn step(&self, state: &Array1<f64>) -> Array1<f64> {
        let n = state.len();
        let mut next_state = Array1::zeros(n);
        
        for i in 0..n {
            let mut val = (1.0 - self.gamma) * state[i];
            if i > 0 {
                val += self.beta * state[i - 1];
            }
            if i + 1 < n {
                val += self.beta * state[i + 1];
            }
            next_state[i] = val;
        }

        next_state
    }
}

#[cfg(kani)]
mod renorm_alpha_proofs {
    use super::*;
    use ndarray::arr1;

    #[kani::proof]
    fn verify_filter_phase_is_contractive() {
        let gamma: f64 = kani::any();
        let beta: f64 = kani::any();
        
        kani::assume(gamma > 0.0 && gamma < 1.0);
        kani::assume(beta > 0.0);
        
        // Force strict Filter Phase: 2*beta < gamma
        kani::assume(2.0 * beta <= gamma - 0.001);

        let alpha = RenormalizationAlpha::new(gamma, beta);

        // Symbolic 3-prime window state
        let s0: f64 = kani::any();
        let s1: f64 = kani::any();
        let s2: f64 = kani::any();
        
        let state_norm_sq = s0 * s0 + s1 * s1 + s2 * s2;
        kani::assume(state_norm_sq <= 100.0);
        
        let state = arr1(&[s0, s1, s2]);
        let next_state = alpha.step(&state);
        
        let next_norm_sq = next_state.dot(&next_state);

        // Filter Phase guarantees contraction: ||v'||^2 < ||v||^2
        assert!(
            next_norm_sq <= state_norm_sq + 1e-9,
            "Filter phase failed to contract state vector"
        );
    }
}
