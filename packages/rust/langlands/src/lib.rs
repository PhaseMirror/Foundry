use num_complex::Complex64;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
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

/// Compute Dirichlet series at complex `s`: L(s) = Σ a_n / n^s
/// This extends the prime coefficients into prime powers based on multiplicativity,
/// closely matching the Python `compute_dirichlet_series` in Langlands-Prism.
pub fn compute_dirichlet_series(
    coefficients: &HashMap<u64, f64>,
    s: Complex64,
    max_n: u64,
) -> Complex64 {
    let mut a = vec![0.0; (max_n + 1) as usize];
    a[1] = 1.0;
    
    // Fill prime powers
    for (&p, &a_p) in coefficients {
        let mut pk = p;
        let mut k = 1;
        while pk <= max_n {
            a[pk as usize] = a_p.powi(k);
            pk *= p;
            k += 1;
        }
    }
    
    // Multiplicative combinations can be added here. Currently matches Python's prime-power baseline.
    let mut l_val = Complex64::new(0.0, 0.0);
    for n in 1..=max_n {
        if a[n as usize] != 0.0 {
            let n_complex = Complex64::new(n as f64, 0.0);
            l_val += a[n as usize] / n_complex.powc(s);
        }
    }
    l_val
}

/// Compute Euler Product form: L(s) = Π (1 - a_p / p^s)^{-1}
/// Converges for Re(s) > 1 when |a_p| < p.
pub fn compute_euler_product(
    coefficients: &HashMap<u64, f64>,
    s: Complex64,
) -> Complex64 {
    let mut l_val = Complex64::new(1.0, 0.0);
    for (&p, &a_p) in coefficients {
        let p_complex = Complex64::new(p as f64, 0.0);
        let p_s = p_complex.powc(s);
        let one = Complex64::new(1.0, 0.0);
        let euler_factor = one / (one - (Complex64::new(a_p, 0.0) / p_s));
        l_val *= euler_factor;
    }
    l_val
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

    #[test]
    fn test_dirichlet_series() {
        let mut coeffs = HashMap::new();
        coeffs.insert(2, 0.5);
        coeffs.insert(3, 0.3);
        
        // Evaluate at s = 1.0 + 0.0i
        let s = Complex64::new(1.0, 0.0);
        let l_val = compute_dirichlet_series(&coeffs, s, 5);
        
        // Expected for n=1: 1.0/1 = 1.0
        // Expected for n=2: 0.5/2 = 0.25
        // Expected for n=3: 0.3/3 = 0.1
        // Expected for n=4: (0.5^2)/4 = 0.0625
        // Expected for n=5: 0.0/5 = 0.0
        // Sum = 1.4125
        assert!((l_val.re - 1.4125).abs() < 1e-12);
    }

    #[test]
    fn test_euler_product() {
        let mut coeffs = HashMap::new();
        coeffs.insert(2, 0.5);
        
        // Evaluate at s = 1.0 + 0.0i
        let s = Complex64::new(1.0, 0.0);
        let l_val = compute_euler_product(&coeffs, s);
        
        // Expected: (1 - 0.5 / 2^1)^-1 = (1 - 0.25)^-1 = (0.75)^-1 = 4/3 = 1.333333333
        assert!((l_val.re - (4.0 / 3.0)).abs() < 1e-12);
    }
}
