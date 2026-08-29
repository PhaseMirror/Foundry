use serde::{Deserialize, Serialize};
use crate::core::{DELTA_I, ALPHA_NL};

/// Multiplicity Transformation Operator Evaluation Result.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MOperatorOutput {
    pub prime_id: u64,
    pub input_value: f64,
    pub linear_prime_term: f64,
    pub nonlinear_reg_term: f64,
    pub self_referential_term: f64,
    pub fractal_residual: f64,
    pub total_transformed_value: f64,
}

/// Non-linear regularization term:
///
/// $$R_{\text{nl}}(w) = \frac{\alpha \cdot w^2}{1 + w^2}$$
pub fn nonlinear_regularization(w: f64, alpha: f64) -> f64 {
    let w_sq = w * w;
    (alpha * w_sq) / (1.0 + w_sq)
}

/// Self-referential gradient term:
///
/// $$T_{p_i}(\text{self}) = \delta_I \cdot \nabla T_{p_i}$$
pub fn self_referential_term(grad: f64, delta_i: f64) -> f64 {
    delta_i * grad
}

/// Fractal residual perturbation term $S_f(t, p_i)$:
pub fn fractal_residual(t: u64, prime_id: u64) -> f64 {
    let phase = ((t as f64 * 0.17) + (prime_id as f64 * 0.31)).sin();
    0.01 * phase
}

/// Prime-indexed Transformation Operator:
///
/// $$T_{p_i}(M) = p_i \cdot M + R_{\text{nl}}(M) + \delta_I \cdot \nabla M + S_f$$
pub fn evaluate_m_operator(
    m_val: f64,
    prime_id: u64,
    grad_val: f64,
    t: u64,
) -> MOperatorOutput {
    let p_term = prime_id as f64 * m_val;
    let r_term = nonlinear_regularization(m_val, ALPHA_NL);
    let self_term = self_referential_term(grad_val, DELTA_I);
    let sf_term = fractal_residual(t, prime_id);

    let total = p_term + r_term + self_term + sf_term;

    MOperatorOutput {
        prime_id,
        input_value: m_val,
        linear_prime_term: p_term,
        nonlinear_reg_term: r_term,
        self_referential_term: self_term,
        fractal_residual: sf_term,
        total_transformed_value: total,
    }
}

/// Iterative normalized contraction mapping to detect fractal fixed point $M_\infty$:
pub fn iterate_normalized_m_operator(
    initial: f64,
    prime_id: u64,
    steps: usize,
) -> Vec<f64> {
    let mut history = Vec::with_capacity(steps + 1);
    let mut curr = initial;
    history.push(curr);

    for t in 0..steps {
        let out = evaluate_m_operator(curr, prime_id, 0.01, t as u64);
        // Normalize by prime index to observe attractor fixed point
        curr = (out.total_transformed_value / prime_id as f64).clamp(-100.0, 100.0);
        history.push(curr);
    }

    history
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_nonlinear_regularization_bounded_by_alpha() {
        let r0 = nonlinear_regularization(0.0, 0.5);
        assert_eq!(r0, 0.0);

        let r_large = nonlinear_regularization(1000.0, 0.5);
        assert!(r_large < 0.5);
        assert!(r_large > 0.499);
    }

    #[test]
    fn test_evaluate_m_operator_scaling() {
        let out7 = evaluate_m_operator(1.0, 7, 0.1, 0);
        let out11 = evaluate_m_operator(1.0, 11, 0.1, 0);

        assert!(out11.total_transformed_value > out7.total_transformed_value);
        assert!(out7.linear_prime_term == 7.0);
    }
}
