use ndarray::{Array1, Array2};
use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum PirtmError {
    #[error("Dimension mismatch: expected {expected}, found {found}")]
    DimensionMismatch { expected: usize, found: usize },
    #[error("Contractivity violation: bound {bound} >= gamma {gamma}")]
    ContractivityViolation { bound: f64, gamma: f64 },
    #[error("Invalid parameter: {0}")]
    InvalidParameter(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MultiplicityParams {
    pub version: String,
    pub prime_set: Vec<u64>,
    pub scales: [u32; 4],
    pub q: u64,
    pub alpha: f64,
    pub lambda_m: f64,
    pub gamma: f64,
    pub noise_type: String,
    pub noise_k: u32,
    #[serde(default = "default_scales_version")]
    pub scales_version: String,
}

fn default_scales_version() -> String {
    "v1".to_string()
}

pub struct PirtmMetadata {
    pub q_t: f64,
    pub c_lambda: f64,
    pub margin: f64,
}

/// Execute one step of the PIRTM recurrence.
/// X_{t+1} = (1 - λ_m)X_t + λ_m P(Ξ_t X_t + Λ_t T(X_t) + G_t)
pub fn step(
    x_t: &Array1<f64>,
    xi_t: &Array2<f64>,
    lambda_t: &Array2<f64>,
    g_t: Option<&Array1<f64>>,
    epsilon: f64,
    lambda_m: f64,
    l_t: f64,
) -> Result<(Array1<f64>, PirtmMetadata), PirtmError> {
    let dim = x_t.len();
    if xi_t.nrows() != dim || xi_t.ncols() != dim {
        return Err(PirtmError::DimensionMismatch { expected: dim, found: xi_t.nrows() });
    }
    if lambda_t.nrows() != dim || lambda_t.ncols() != dim {
        return Err(PirtmError::DimensionMismatch { expected: dim, found: lambda_t.nrows() });
    }

    let g = if let Some(g) = g_t {
        if g.len() != dim {
            return Err(PirtmError::DimensionMismatch { expected: dim, found: g.len() });
        }
        g.clone()
    } else {
        Array1::zeros(dim)
    };

    // term1 = Ξ_t * X_t
    let term1 = xi_t.dot(x_t);

    // T(X_t) = sigmoid(X_t)
    let tx_t = x_t.mapv(|val| 1.0 / (1.0 + (-val).exp()));

    // term2 = Λ_t * T(X_t)
    let term2 = lambda_t.dot(&tx_t);

    // Y_t = Ξ_t X_t + Λ_t T(X_t) + G_t
    let y_t = term1 + term2 + g;

    // P(Y_t) = clip(Y_t, -1, 1)
    let py_t = y_t.mapv(|val| val.clamp(-1.0, 1.0));

    // X_{t+1} = (1 - λ_m)X_t + λ_m P(Y_t)
    let x_next = if (lambda_m - 1.0).abs() < f64::EPSILON {
        py_t
    } else {
        (1.0 - lambda_m) * x_t + lambda_m * py_t
    };

    // Contractivity metric
    // c_lambda = (1 - λ_m) + λ_m * (||Ξ||_2 + ||Λ||_2 * L_T)
    // Note: We use spectral norm (L2) for matrices. 
    // ndarray doesn't have a built-in spectral norm, so we'll use Frobenius norm as a surrogate or implement a simple power iteration if needed.
    // For now, let's use Frobenius norm just for the sake of implementation, but we should ideally match the Python backend.
    
    // Actually, let's implement a basic spectral norm via power iteration for consistency with the Python `norm(..., order=2)`.
    let n_xi = spectral_norm(xi_t);
    let n_lam = spectral_norm(lambda_t);

    let c_lambda = (1.0 - lambda_m) + lambda_m * (n_xi + n_lam * l_t);
    let margin = (1.0 - epsilon) - c_lambda;

    Ok((
        x_next,
        PirtmMetadata {
            q_t: n_xi + n_lam * l_t,
            c_lambda,
            margin,
        },
    ))
}

fn spectral_norm(matrix: &Array2<f64>) -> f64 {
    // Power iteration for spectral norm (largest singular value)
    // This is a simple approximation.
    let dim = matrix.ncols();
    let mut v = Array1::from_elem(dim, 1.0 / (dim as f64).sqrt());
    
    // Compute A^T * A
    let ata = matrix.t().dot(matrix);
    
    for _ in 0..10 {
        let w = ata.dot(&v);
        let norm = w.dot(&w).sqrt();
        if norm < 1e-10 {
            return 0.0;
        }
        v = w / norm;
    }
    
    (v.dot(&ata.dot(&v))).sqrt()
}

pub mod multiplicity_lwe;
pub mod gate;
pub mod bytecode;
pub mod prime_recursive;

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn test_step_contractivity() {
        let x_t = array![1.0, 0.5];
        let xi_t = array![[0.8, 0.0], [0.0, 0.8]];
        let lambda_t = array![[0.1, 0.0], [0.0, 0.1]];
        let epsilon = 0.05;
        let lambda_m = 1.0;
        let l_t = 1.0;

        let (x_next, metadata) = step(&x_t, &xi_t, &lambda_t, None, epsilon, lambda_m, l_t).unwrap();

        assert_eq!(x_next.len(), 2);
        assert!(metadata.margin > 0.0);
        println!("x_next: {:?}", x_next);
        println!("margin: {}", metadata.margin);
    }

    #[test]
    fn test_spectral_norm() {
        let matrix = array![[2.0, 0.0], [0.0, 3.0]];
        let norm = spectral_norm(&matrix);
        assert!((norm - 3.0).abs() < 1e-5);
    }

    #[test]
    fn test_csl_gate_basic() {
        use crate::gate::csl_gate::{CslGate, CslGateParams};
        
        let mut gate = CslGate::new(Some(CslGateParams::default()), None);
        let x = array![1.0, 1.0];
        let sigma = array![[1.0, 0.0], [0.0, 1.0]];
        let weights = array![0.6, 0.7, 0.8]; // All above 0.5 threshold
        
        let (passed, reason) = gate.check(&x, 0, &sigma, &weights);
        assert!(passed);
        assert_eq!(reason, "pass");
    }

    #[test]
    fn test_rate_limiter_convergence() {
        use crate::gate::rate_limiter::{RateLimiter, RateLimiterParams};
        
        let rl = RateLimiter::new(Some(RateLimiterParams {
            r: 5,
            n: 50,
            delta_target: 0.01,
            delta_0: 1.0,
        })).unwrap();
        
        let bound = rl.convergence_bound();
        assert!(bound > 0);
        println!("Convergence bound: {}", bound);
    }

    #[test]
    fn test_bytecode_serialization() {
        use crate::bytecode::{PirtmBytecode, PirtmBytecodeContent, ModuleMetadata};
        
        let content = PirtmBytecodeContent {
            modules: vec![ModuleMetadata {
                name: "test_module".to_string(),
                prime_index: 7919,
                epsilon: 0.05,
                op_norm_t: 0.8,
                contractivity_check: "PASS".to_string(),
                proof_hash: "abcd".to_string(),
                timestamp: chrono::Utc::now().to_rfc3339(),
            }],
            coupling: "#pirtm.unresolved_coupling".to_string(),
            mlir_source: "module { }".to_string(),
            audit_trail: vec!["Day 14: test".to_string()],
        };
        
        let bytecode = PirtmBytecode::new(content);
        let json = serde_json::to_string(&bytecode).unwrap();
        assert!(json.contains("pirtm.bc"));
    }

    #[test]
    fn test_prime_recursive_contractor() {
        use crate::prime_recursive::{generate_primes, compute_contraction_parameter};
        
        let primes = generate_primes(10);
        assert_eq!(primes.len(), 10);
        assert_eq!(primes[0], 2);
        assert_eq!(primes[9], 29);
        
        let k = compute_contraction_parameter(0.1, 10, -1.5).unwrap();
        assert!(k > 0.0);
        assert!(k < 1.0);
    }

    #[test]
    fn test_prime_recursive_solver() {
        use crate::prime_recursive::DecoupledSolver;
        use ndarray::Array1;
        
        let solver = DecoupledSolver::new(0.5, 2, 0.05).unwrap();
        let t_initial = Array1::from_vec(vec![0.0, 0.0]);
        let f = Array1::from_vec(vec![1.0, 2.0]);
        
        let (final_state, telemetry) = solver.simulate(&t_initial, &f, 100, 1e-6, None);
        assert!(telemetry.len() > 0);
        
        let expected = solver.compute_closed_form(&f);
        let diff = &final_state - &expected;
        assert!(diff.dot(&diff).sqrt() < 1e-5);
    }

    #[test]
    fn test_prime_recursive_commitment() {
        use crate::prime_recursive::{TensorType, Axis, Variance, Sig, compute_weak_commitment};
        use std::collections::HashMap;
        
        let mut map = HashMap::new();
        map.insert("p1".to_string(), 2);
        let sig = Sig::from_map(map);
        
        let tensor = TensorType::new(vec![Axis {
            variance: Variance::Positive,
            signature: sig,
        }]).unwrap();
        
        let commitment = compute_weak_commitment(&tensor);
        assert!(!commitment.is_empty());
        println!("Commitment: {}", commitment);
    }

    #[test]
    fn test_multiplicity_functor_properties() {
        use crate::prime_recursive::MultFunctor;
        use ndarray::Array1;
        
        let functor = MultFunctor::new(10);
        let a = Array1::from_vec(vec![0.1; 10]);
        let b = Array1::from_vec(vec![0.2; 10]);
        
        assert!(functor.verify_additive(&a, &b));
    }
}
