use ndarray::{Array1, Array2};
use faer::prelude::*;
use faer::Mat;

/// Operational Strata Mapping (Λ-RMAM-ZΞ 7.3)
#[derive(Debug, Clone)]
pub enum StratumType {
    S0Physics,    // Adelic Modules (Tensor recursion)
    S2Cognition,  // Operadic Windows (Prime-locked EEG binning)
    S4Collective, // Social Networks (Eigenvalue distributions)
}

#[derive(Debug, Clone)]
pub struct StratumState {
    pub stratum_type: StratumType,
    pub state_vector: Array1<f64>,
    pub metadata: StratumMetadata,
}

#[derive(Debug, Clone)]
pub enum StratumMetadata {
    Adelic { primes: Vec<usize> },
    Operadic { frequency_range: (f64, f64) },
    Social { 
        interaction_matrix: Array2<f64>,
        spectral_gap: f64,
    },
}

impl StratumState {
    pub fn new_s0(primes: Vec<usize>, dim: usize) -> Self {
        StratumState {
            stratum_type: StratumType::S0Physics,
            state_vector: Array1::zeros(dim),
            metadata: StratumMetadata::Adelic { primes },
        }
    }

    pub fn new_s2(min_hz: f64, max_hz: f64, dim: usize) -> Self {
        StratumState {
            stratum_type: StratumType::S2Cognition,
            state_vector: Array1::zeros(dim),
            metadata: StratumMetadata::Operadic { frequency_range: (min_hz, max_hz) },
        }
    }

    pub fn new_s4(dim: usize) -> Self {
        StratumState {
            stratum_type: StratumType::S4Collective,
            state_vector: Array1::zeros(dim),
            metadata: StratumMetadata::Social { 
                interaction_matrix: Array2::eye(dim),
                spectral_gap: 0.0,
            },
        }
    }

    /// Recursive Update specialized for the stratum type.
    pub fn recursive_update(&mut self, input: &Array1<f64>) {
        match self.stratum_type {
            StratumType::S0Physics => {
                self.state_vector = self.state_vector.clone() * 0.85 + input * 0.15;
            }
            StratumType::S2Cognition => {
                self.state_vector = self.state_vector.clone() * 0.9 + input * 0.1;
            }
            StratumType::S4Collective => {
                self.update_s4(input);
            }
        }
    }

    /// S4 Specific: Eigenvalue distribution updates.
    fn update_s4(&mut self, input: &Array1<f64>) {
        if let StratumMetadata::Social { interaction_matrix, spectral_gap } = &mut self.metadata {
            let dim = interaction_matrix.nrows();
            
            // 1. Rank-1 update to the interaction matrix based on input resonance
            // M_{t+1} = (1 - \lambda) M_t + \lambda (v \cdot v^T)
            let lambda = 0.1;
            for i in 0..dim {
                for j in 0..dim {
                    interaction_matrix[[i, j]] = (1.0 - lambda) * interaction_matrix[[i, j]] 
                        + lambda * (input[i] * input[j]);
                }
            }

            // 2. Map ndarray to faer for spectral analysis
            let faer_mat = Mat::from_fn(dim, dim, |i, j| interaction_matrix[[i, j]]);
            
            // 3. Compute Eigenvalues (Eigendecomposition)
            // Note: For symmetric matrices, selfadjoint_eigendecomposition is faster
            let eig = faer_mat.selfadjoint_eigendecomposition(faer::Side::Upper);
            let mut eigenvalues: Vec<f64> = eig.s().column_vector().iter().map(|&x| x).collect();
            eigenvalues.sort_by(|a, b| b.partial_cmp(a).unwrap());

            // 4. Update Spectral Gap (difference between top two eigenvalues)
            if eigenvalues.len() >= 2 {
                *spectral_gap = eigenvalues[0] - eigenvalues[1];
            }

            // 5. Update state vector to reflect the top eigenvalue distribution (Perron-Frobenius vector)
            // This represents the emergent collective focus.
            self.state_vector = Array1::from_vec(eigenvalues.iter().take(self.state_vector.len()).cloned().collect());
        }
    }
}
