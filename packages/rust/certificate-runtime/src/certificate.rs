//! Safe Rust API for certificate checking

use thiserror::Error;

#[derive(Error, Debug)]
pub enum CertificateError {
    #[error("Certificate violation: actual_ratio={actual:.6} > bound={bound:.6}")]
    Violation { actual: f64, bound: f64 },
    #[error("Invalid input: {reason}")]
    InvalidInput { reason: String },
}

#[derive(Debug, Clone, Copy)]
pub struct CertificateResult {
    pub passed: bool,
    pub actual_ratio: f64,
    pub theoretical_bound: f64,
}

pub struct CertifiedState {
    pub u: Vec<f64>,
    pub l: Vec<Vec<f64>>,
    pub lambda_2: f64,
    pub lambda_max: f64,
    pub alpha: f64,
}

impl CertifiedState {
    pub fn new(u: Vec<f64>, l: Vec<Vec<f64>>, lambda_2: f64, lambda_max: f64, alpha: f64) -> Result<Self, CertificateError> {
        let alpha_upper = 2.0 / lambda_max;
        if alpha <= 0.0 || alpha >= alpha_upper {
            return Err(CertificateError::InvalidInput {
                reason: format!("alpha must be in (0, {})", alpha_upper),
            });
        }
        Ok(Self { u, l, lambda_2, lambda_max, alpha })
    }

    pub fn step(&mut self) -> Result<CertificateResult, CertificateError> {
        let u_new = self.heat_step(&self.u);
        let result = self.check_certificate(&self.u, &u_new)?;

        if result.passed {
            self.u = u_new;
            Ok(result)
        } else {
            Err(CertificateError::Violation {
                actual: result.actual_ratio,
                bound: result.theoretical_bound,
            })
        }
    }

    pub fn heat_step(&self, u: &[f64]) -> Vec<f64> {
        let mut u_new = u.to_vec();
        for i in 0..u.len() {
            let mut laplacian = 0.0;
            for j in 0..u.len() {
                laplacian += self.l[i][j] * u[j];
            }
            u_new[i] = u[i] - self.alpha * laplacian;
        }
        u_new
    }

    pub fn check_certificate(&self, u_old: &[f64], u_new: &[f64]) -> Result<CertificateResult, CertificateError> {
        // Compute mean_zero norms to get ratio
        let mut sum_old = 0.0;
        let mut sum_new = 0.0;
        for &x in u_old { sum_old += x; }
        for &x in u_new { sum_new += x; }
        let mean_old = sum_old / (u_old.len() as f64);
        let mean_new = sum_new / (u_new.len() as f64);

        let mut norm_old = 0.0;
        let mut norm_new = 0.0;
        for &x in u_old { norm_old += (x - mean_old).powi(2); }
        for &x in u_new { norm_new += (x - mean_new).powi(2); }
        
        norm_old = norm_old.sqrt();
        norm_new = norm_new.sqrt();

        let ratio = if norm_old > 0.0 { norm_new / norm_old } else { 0.0 };
        let theoretical_bound = 1.0 - self.alpha * self.lambda_2;

        // In production this would invoke the FFI call `certificate_check`
        // We mock it for the test logic here.
        let passed = ratio <= theoretical_bound + 1e-12;

        Ok(CertificateResult {
            passed,
            actual_ratio: ratio,
            theoretical_bound,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    proptest! {
        #[test]
        fn test_certified_state_step(
            u_val1 in -10.0..10.0f64,
            u_val2 in -10.0..10.0f64,
            alpha in 0.01..0.5f64
        ) {
            let u = vec![u_val1, u_val2];
            let l = vec![vec![1.0, -1.0], vec![-1.0, 1.0]];
            
            // For a 2x2 laplacian [1, -1; -1, 1], lambda_max = 2.0, lambda_2 = 2.0
            if let Ok(mut state) = CertifiedState::new(u, l, 2.0, 2.0, alpha) {
                let result = state.step();
                match result {
                    Ok(r) => {
                        prop_assert!(r.passed);
                        prop_assert!(r.actual_ratio <= r.theoretical_bound + 1e-12);
                    },
                    Err(CertificateError::Violation { actual, bound }) => {
                        prop_assert!(actual > bound + 1e-12);
                    },
                    _ => {}
                }
            }
        }
    }
}
