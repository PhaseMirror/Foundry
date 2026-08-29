//! Weighted-ℓ₁ projection with KKT certificates and dual gap.
//!
//! The projection of $v$ onto $\Omega = \{x : \sum_k \omega_k |x_k| \le \Lambda_m\}$
//! is given by weighted soft-thresholding:
//! $$x_k^* = \text{sign}(v_k) \max\{|v_k| - \tau \omega_k, 0\}$$
//! with $\tau$ chosen so $\sum_k \omega_k |x_k^*| = \Lambda_m$ when active.

use thiserror::Error;

#[derive(Debug, Error)]
pub enum ProjectionError {
    #[error("weights must be positive")]
    NonPositiveWeights,
    #[error("budget must be non-negative")]
    NegativeBudget,
}

/// Configuration for the weighted-ℓ₁ projection.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ProjectionConfig {
    pub max_iter: usize,
    pub tol: f64,
    pub feasibility_tol: f64,
}

impl Default for ProjectionConfig {
    fn default() -> Self {
        Self {
            max_iter: 80,
            tol: 1e-8,
            feasibility_tol: 1e-8,
        }
    }
}

/// Certificate from the weighted-ℓ₁ projection.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ProjectionCertificate {
    pub feasible: bool,
    pub tau: f64,
    pub gaplb: f64,
    pub primal: f64,
    pub dual: f64,
    pub mass: f64,
    pub budget: f64,
    pub complementary_slackness: bool,
}

/// Project $v$ onto $\{x : \sum_k \omega_k |x_k| \le \Lambda\}$.
///
/// Returns the projected vector and a KKT certificate.
pub fn project_weighted_l1(
    v: &[f64],
    omega: &[f64],
    lambda: f64,
    config: &ProjectionConfig,
) -> Result<(Vec<f64>, ProjectionCertificate), ProjectionError> {
    let n = v.len();
    assert_eq!(omega.len(), n);

    if omega.iter().any(|&w| w <= 0.0) {
        return Err(ProjectionError::NonPositiveWeights);
    }
    if lambda < 0.0 {
        return Err(ProjectionError::NegativeBudget);
    }

    // Check if v is already feasible
    let mass: f64 = v.iter().zip(omega.iter()).map(|(x, w)| w * x.abs()).sum();
    if mass <= lambda {
        return Ok((
            v.to_vec(),
            ProjectionCertificate {
                feasible: true,
                tau: 0.0,
                gaplb: 0.0,
                primal: 0.0,
                dual: 0.0,
                mass,
                budget: lambda,
                complementary_slackness: true,
            },
        ));
    }

    // Bisection on tau
    let max_v_over_w: f64 = v.iter()
        .zip(omega.iter())
        .map(|(x, w)| x.abs() / w)
        .fold(0.0, f64::max);

    let mut tau_lo = 0.0;
    let mut tau_hi = max_v_over_w;
    let mut tau = 0.0;

    for _ in 0..config.max_iter {
        tau = 0.5 * (tau_lo + tau_hi);
        let x: Vec<f64> = v.iter()
            .zip(omega.iter())
            .map(|(vi, wi)| vi.signum() * (vi.abs() - tau * wi).max(0.0))
            .collect();
        let mass: f64 = x.iter().zip(omega.iter()).map(|(xi, wi)| wi * xi.abs()).sum();

        if mass > lambda {
            tau_lo = tau;
        } else {
            tau_hi = tau;
        }

        if (mass - lambda).abs() <= config.tol {
            break;
        }
    }

    // Final projection with tau_hi (ensures feasibility)
    tau = tau_hi;
    let x: Vec<f64> = v.iter()
        .zip(omega.iter())
        .map(|(vi, wi)| vi.signum() * (vi.abs() - tau * wi).max(0.0))
        .collect();

    let mass: f64 = x.iter().zip(omega.iter()).map(|(xi, wi)| wi * xi.abs()).sum();
    let feasible = mass <= lambda + config.feasibility_tol;

    // Primal objective: 0.5 * ||x - v||^2
    let primal: f64 = x.iter().zip(v.iter()).map(|(xi, vi)| (xi - vi).powi(2)).sum::<f64>() * 0.5;

    // Dual objective: tau * Lambda - sum max(|v_k| - tau*omega_k, 0)^2 / (2*omega_k)
    // Simplified: tau * Lambda - sum (|v_k| - tau*omega_k)_+^2 / (2*omega_k)
    let dual: f64 = tau * lambda
        - v.iter()
            .zip(omega.iter())
            .map(|(vi, wi)| {
                let shrink = (vi.abs() - tau * wi).max(0.0);
                if *wi > 0.0 {
                    shrink.powi(2) / (2.0 * wi)
                } else {
                    0.0
                }
            })
            .sum::<f64>();

    let gaplb = (primal - dual).max(0.0);

    // Complementary slackness: tau * (Lambda - sum omega_k |x_k|) = 0
    let cs_violation = (tau * (lambda - mass)).abs();

    Ok((
        x,
        ProjectionCertificate {
            feasible,
            tau,
            gaplb,
            primal,
            dual,
            mass,
            budget: lambda,
            complementary_slackness: cs_violation <= config.tol,
        },
    ))
}

/// Softmax Jacobian upper bound: $\|J_{\text{softmax}}\|_{1 \to 1} \le \max_i 2 s_i(1-s_i)$.
pub fn softmax_ub(logits: &[f64]) -> f64 {
    let max_logit = logits.iter().fold(f64::NEG_INFINITY, |a, &b| a.max(b));
    let exps: Vec<f64> = logits.iter().map(|&l| (l - max_logit).exp()).collect();
    let sum: f64 = exps.iter().sum();
    let probs: Vec<f64> = exps.iter().map(|&e| e / sum).collect();

    probs
        .iter()
        .map(|&s| 2.0 * s * (1.0 - s))
        .fold(0.0, f64::max)
}

/// SlopeUB: end-to-end $\ell_1$-Lipschitz upper bound.
///
/// $\text{SlopeUB} = \prod_\ell B_\ell \times \prod_{\text{softmax}} \text{SoftmaxUB}$
pub fn slopeub(linear_norms: &[f64], softmax_ubs: &[f64]) -> f64 {
    let mut result = 1.0;
    for &n in linear_norms {
        result *= n;
    }
    for &u in softmax_ubs {
        result *= u;
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_projection_feasible_input() {
        let v = vec![0.1, 0.2, 0.3];
        let omega = vec![1.0, 1.0, 1.0];
        let (x, cert) = project_weighted_l1(&v, &omega, 1.0, &ProjectionConfig::default()).unwrap();
        assert_eq!(x, v);
        assert!(cert.feasible);
        assert!((cert.tau).abs() < 1e-10);
    }

    #[test]
    fn test_projection_shrinks() {
        let v = vec![10.0, 10.0, 10.0];
        let omega = vec![1.0, 1.0, 1.0];
        let lambda = 1.0;
        let (x, cert) = project_weighted_l1(&v, &omega, lambda, &ProjectionConfig::default()).unwrap();

        // All components should be shrunk
        for &xi in &x {
            assert!(xi < 10.0);
        }
        // Mass should equal budget
        let mass: f64 = x.iter().zip(omega.iter()).map(|(xi, wi)| wi * xi.abs()).sum();
        assert!((mass - lambda).abs() < 1e-6);
        assert!(cert.feasible);
    }

    #[test]
    fn test_projection_zero_budget() {
        let v = vec![5.0, -3.0, 2.0];
        let omega = vec![1.0, 1.0, 1.0];
        let (x, cert) = project_weighted_l1(&v, &omega, 0.0, &ProjectionConfig::default()).unwrap();
        for &xi in &x {
            assert!((xi).abs() < 1e-10);
        }
        assert!(cert.feasible);
    }

    #[test]
    fn test_projection_weights() {
        let v = vec![1.0, 1.0];
        let omega = vec![1.0, 10.0]; // Second component is expensive
        let lambda = 1.0;
        let (x, _) = project_weighted_l1(&v, &omega, lambda, &ProjectionConfig::default()).unwrap();

        // First component should be kept, second should be shrunk more
        assert!(x[0] > x[1]);
    }

    #[test]
    fn test_complementary_slackness() {
        let v = vec![5.0, 5.0];
        let omega = vec![1.0, 1.0];
        let lambda = 5.0;
        let (_, cert) = project_weighted_l1(&v, &omega, lambda, &ProjectionConfig::default()).unwrap();
        assert!(cert.complementary_slackness);
        assert!(cert.gaplb < 1e-6);
    }

    #[test]
    fn test_softmax_ub() {
        // Uniform distribution: s_i = 1/n, UB = 2*(1/n)*(1-1/n)
        let logits = vec![0.0, 0.0, 0.0];
        let ub = softmax_ub(&logits);
        let expected = 2.0 * (1.0 / 3.0) * (2.0 / 3.0);
        assert!((ub - expected).abs() < 1e-10);
    }

    #[test]
    fn test_slopeub() {
        let linear_norms = vec![2.0, 3.0];
        let softmax_ubs = vec![0.5, 0.5];
        let s = slopeub(&linear_norms, &softmax_ubs);
        assert!((s - 1.5).abs() < 1e-10); // 2*3*0.5*0.5 = 1.5
    }
}
