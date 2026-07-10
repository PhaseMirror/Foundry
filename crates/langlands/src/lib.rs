use num_complex::Complex64;
use std::collections::{HashMap, HashSet};
use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum LanglandsError {
    #[error("Evaluation failed: {0}")]
    EvaluationError(String),
}

/// GL(1) phase rotation: v_p → v_p · e^(i · ln p)
pub fn langlands_automorphy(prime_tensor: &HashMap<u64, Complex64>) -> HashMap<u64, Complex64> {
    prime_tensor
        .iter()
        .map(|(&p, &v)| {
            let rotation = Complex64::from_polar(1.0, (p as f64).ln());
            (p, v * rotation)
        })
        .collect()
}

/// Natural G_L action on prime-indexed tensor via multiplicity map.
/// The action is: φ_p(v_p) = v_p · M(T_t, p)
pub fn langlands_action<F>(
    prime_tensor: &HashMap<u64, Complex64>,
    multiplicity_fn: F,
) -> HashMap<u64, Complex64>
where
    F: Fn(u64) -> f64,
{
    prime_tensor
        .iter()
        .map(|(&p, &v)| (p, v * multiplicity_fn(p)))
        .collect()
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CommutationResult {
    pub commutes: bool,
    pub max_deviation: f64,
    pub max_prime: Option<u64>,
    pub epsilon: f64,
}

/// Verify G_L commutation: |(G_L U_k - U_k G_L)(ψ)|_p < ε_L at all primes.
pub fn verify_langlands_commutes<F, M>(
    u_k: F,
    psi: &HashMap<u64, Complex64>,
    multiplicity_fn: M,
    epsilon: f64,
) -> Result<CommutationResult, LanglandsError>
where
    F: Fn(&HashMap<u64, Complex64>) -> Result<HashMap<u64, Complex64>, String>,
    M: Fn(u64) -> f64,
{
    // LHS = G_L(U_k(ψ))
    let u_k_psi = u_k(psi).map_err(LanglandsError::EvaluationError)?;
    let lhs = langlands_action(&u_k_psi, &multiplicity_fn);

    // RHS = U_k(G_L(ψ))
    let g_l_psi = langlands_action(psi, &multiplicity_fn);
    let rhs = u_k(&g_l_psi).map_err(LanglandsError::EvaluationError)?;

    let primes: HashSet<u64> = lhs.keys().cloned().chain(rhs.keys().cloned()).collect();
    let mut max_deviation = 0.0;
    let mut max_prime = None;

    for &p in &primes {
        let v_lhs = lhs.get(&p).cloned().unwrap_or(Complex64::new(0.0, 0.0));
        let v_rhs = rhs.get(&p).cloned().unwrap_or(Complex64::new(0.0, 0.0));
        let dev = (v_lhs - v_rhs).norm();
        if dev > max_deviation {
            max_deviation = dev;
            max_prime = Some(p);
        }
    }

    Ok(CommutationResult {
        commutes: max_deviation < epsilon,
        max_deviation,
        max_prime,
        epsilon,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_langlands_automorphy() {
        let mut tensor = HashMap::new();
        tensor.insert(2, Complex64::new(1.0, 0.0));
        let rotated = langlands_automorphy(&tensor);
        let expected = Complex64::from_polar(1.0, 2.0f64.ln());
        assert!((rotated[&2] - expected).norm() < 1e-12);
    }

    #[test]
    fn test_langlands_action() {
        let mut tensor = HashMap::new();
        tensor.insert(3, Complex64::new(1.0, 0.0));
        let action = langlands_action(&tensor, |p| p as f64);
        assert!((action[&3] - Complex64::new(3.0, 0.0)).norm() < 1e-12);
    }

    #[test]
    fn test_langlands_commutes() {
        let mut psi = HashMap::new();
        psi.insert(2, Complex64::new(1.0, 0.0));
        
        // Identity operator commutes with any action
        let identity = |t: &HashMap<u64, Complex64>| Ok(t.clone());
        let result = verify_langlands_commutes(identity, &psi, |p| p as f64, 1e-8).unwrap();
        assert!(result.commutes);
        assert!(result.max_deviation < 1e-12);
    }
}
