//! Contractive Safety Projection (CSP) Loop & Contraction Certification

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CspMetrics {
    pub alpha_used: f64,
    pub lf_operator: f64,
    pub slope_ub: f64,
    pub gap_lb: f64,
    pub is_contractive: bool,
    pub backtracks: usize,
}

pub struct CspController {
    pub initial_alpha: f64,
    pub min_alpha: f64,
    pub max_backtracks: usize,
}

impl CspController {
    pub fn new(initial_alpha: f64, min_alpha: f64) -> Self {
        Self {
            initial_alpha: initial_alpha.clamp(0.01, 1.0),
            min_alpha: min_alpha.clamp(1e-4, 0.5),
            max_backtracks: 10,
        }
    }

    /// Computes SlopeUB = (1 - α) + α * L_F and GapLB = 1 - SlopeUB.
    pub fn compute_contraction_bounds(alpha: f64, lf: f64) -> (f64, f64, bool) {
        let slope_ub = (1.0 - alpha) + alpha * lf;
        let gap_lb = 1.0 - slope_ub;
        let is_contractive = slope_ub < 1.0 && gap_lb > 0.0;
        (slope_ub, gap_lb, is_contractive)
    }

    /// Step state with backtracking contraction certification.
    /// If certified, returns next state and metrics; otherwise fails closed and retains current state.
    pub fn step_1d<F, P>(
        &self,
        current_state: f64,
        operator_fn: F,
        operator_lipschitz: f64,
        projector_fn: P,
    ) -> Result<(f64, CspMetrics), String>
    where
        F: Fn(f64) -> f64,
        P: Fn(f64) -> f64,
    {
        let mut alpha = self.initial_alpha;
        let mut backtracks = 0;

        while alpha >= self.min_alpha && backtracks <= self.max_backtracks {
            let (slope_ub, gap_lb, is_contractive) =
                Self::compute_contraction_bounds(alpha, operator_lipschitz);

            if is_contractive {
                let candidate = (1.0 - alpha) * current_state + alpha * operator_fn(current_state);
                let projected = projector_fn(candidate);
                return Ok((
                    projected,
                    CspMetrics {
                        alpha_used: alpha,
                        lf_operator: operator_lipschitz,
                        slope_ub,
                        gap_lb,
                        is_contractive: true,
                        backtracks,
                    },
                ));
            }

            alpha *= 0.5;
            backtracks += 1;
        }

        Err(format!(
            "CSP Contraction Certification Failed: operator L_F = {} exceeds safe bound",
            operator_lipschitz
        ))
    }
}
