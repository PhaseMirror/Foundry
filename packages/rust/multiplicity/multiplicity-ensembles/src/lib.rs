use serde::{Serialize, Deserialize};
use thiserror::Error;

#[derive(Error, Debug, Serialize, Deserialize, Clone)]
pub enum ContractivityError {
    #[error("Global spectral radius exceeds threshold ({rho_global} >= 9500)")]
    EnsembleUnstable { rho_global: u64, delta: i64 },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnsembleModule {
    pub prime_index: usize,
    pub spectral_radius: u64, // Scaled by 10,000 (e.g., 0.82 is 8200)
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnsembleSessionGraph {
    pub modules: Vec<EnsembleModule>,
    pub coupling_matrix: Vec<Vec<u64>>, // Scaled by 10,000
}

impl EnsembleSessionGraph {
    pub fn new(modules: Vec<EnsembleModule>, coupling_matrix: Vec<Vec<u64>>) -> Self {
        Self { modules, coupling_matrix }
    }

    /// Evaluates the global spectral radius using power iteration
    pub fn evaluate_stability(&self) -> Result<(u64, i64), ContractivityError> {
        let n = self.modules.len();
        assert_eq!(self.coupling_matrix.len(), n);
        for row in &self.coupling_matrix {
            assert_eq!(row.len(), n);
        }

        // Construct coupled matrix A = C * diag(rho)
        // A_ij = (C_ij * rho_j) / 10000
        let mut a = vec![vec![0; n]; n];
        for i in 0..n {
            for j in 0..n {
                a[i][j] = (self.coupling_matrix[i][j] * self.modules[j].spectral_radius) / 10000;
            }
        }

        // Power Iteration to find spectral radius
        let mut v = vec![10000; n]; // Initial vector (1.0)
        let mut rho_global = 0;

        for _ in 0..100 {
            let mut w = vec![0; n];
            for i in 0..n {
                let mut sum = 0;
                for j in 0..n {
                    sum += a[i][j] * v[j];
                }
                w[i] = sum / 10000;
            }

            let max_val = *w.iter().max().unwrap_or(&0);
            if max_val == 0 {
                rho_global = 0;
                break;
            }

            rho_global = max_val;

            // Normalize v
            for i in 0..n {
                v[i] = (w[i] * 10000) / max_val;
            }
        }

        let delta = 9500 - rho_global as i64;
        if rho_global >= 9500 {
            return Err(ContractivityError::EnsembleUnstable { rho_global, delta });
        }

        Ok((rho_global, delta))
    }
}
