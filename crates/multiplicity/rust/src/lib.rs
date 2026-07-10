pub mod meta_ensemble;
pub mod gate;
pub mod packs;
pub mod strata;
pub mod evaluation;
pub mod zk_trace;
pub mod ffi;

use ndarray::Array1;

pub struct PrimeOperator {
    pub p: usize,
    pub weight: f64,
}

pub const LAMBDA_M: f64 = 0.85;
pub const ALPHA: f64 = -2.0;

/// Recursion Coefficient (k):
/// k = sum_{p in P_N} lambda_m * p^alpha
pub fn calculate_recursion_coefficient(primes: &[usize]) -> f64 {
    primes.iter().map(|&p| {
        LAMBDA_M * (p as f64).powf(ALPHA)
    }).sum()
}

/// Master Update Rule:
/// M(P_N) = sum_{p in P_N} (lambda_m * p^alpha * T_p) + F
pub fn master_update(
    primes: &[usize],
    operators: &[PrimeOperator],
    state: &Array1<f64>,
    driving_term: &Array1<f64>,
) -> Array1<f64> {
    let mut total_action = Array1::zeros(state.raw_dim());
    
    for (i, &p) in primes.iter().enumerate() {
        let op = &operators[i];
        let p_f = p as f64;
        let weight = LAMBDA_M * op.weight * p_f.powf(ALPHA);
        
        // Use ndarray::Zip for efficient, potentially vectorized element-wise operations
        ndarray::Zip::from(&mut total_action)
            .and(state)
            .for_each(|total, &s| {
                *total += s * weight;
            });
    }
    
    total_action + driving_term
}

/// JS-Coherence Statistic (Jensen-Shannon distance)
pub fn jensen_shannon_coherence(p: &Array1<f64>, q: &Array1<f64>) -> f64 {
    let m = 0.5 * (p + q);
    0.5 * (kl_divergence(p, &m) + kl_divergence(q, &m))
}

fn kl_divergence(p: &Array1<f64>, q: &Array1<f64>) -> f64 {
    p.iter().zip(q.iter()).map(|(&pi, &qi)| {
        if pi > 0.0 {
            pi * (pi / qi).ln()
        } else {
            0.0
        }
    }).sum()
}
