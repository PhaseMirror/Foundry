//! Residue masks, additive logits, and ε-stabilized Sinkhorn.
//!
//! The attention logits are:
//! $$L = \frac{QK^\top}{\sqrt{d}} + \alpha M_p - \beta (1 - M_p)$$
//! followed by row-wise softmax to produce $\widetilde{A}_p$.

use nalgebra::{DMatrix, DVector};
use thiserror::Error;

use crate::group::{CrtEmbedding, legendre_symbol};

#[derive(Debug, Error)]
pub enum MaskError {
    #[error("dimension mismatch: Q has {q_cols} cols, K has {k_cols} cols")]
    DimensionMismatch { q_cols: usize, k_cols: usize },
    #[error("mask size {mask_n} does not match matrix size {mat_n}")]
    MaskSizeMismatch { mask_n: usize, mat_n: usize },
}

/// Configuration for ε-stabilized Sinkhorn normalization.
#[derive(Debug, Clone)]
pub struct SinkhornConfig {
    pub epsilon: f64,
    pub iters: usize,
    pub tol: f64,
}

impl Default for SinkhornConfig {
    fn default() -> Self {
        Self {
            epsilon: 1e-6,
            iters: 5,
            tol: 1e-3,
        }
    }
}

/// Residue mask from Legendre symbol.
///
/// $M_p[i,j] = \mathbf{1}\{\chi_p(\phi(i)-\phi(j))=+1\}$
#[derive(Debug, Clone)]
pub struct ResidueMask {
    pub mask: DMatrix<f64>,
    pub crt: CrtEmbedding,
}

impl ResidueMask {
    /// Build the residue mask from CRT embedding parameters.
    pub fn new(crt: CrtEmbedding) -> Self {
        let mask = crt.residue_mask();
        Self { mask, crt }
    }

    /// Build from a precomputed mask matrix.
    pub fn from_matrix(mask: DMatrix<f64>, crt: CrtEmbedding) -> Self {
        Self { mask, crt }
    }
}

/// Additive logits: $L = QK^\top/\sqrt{d} + \alpha M - \beta(1-M)$.
#[derive(Debug, Clone)]
pub struct AdditiveLogits {
    pub alpha: f64,
    pub beta: f64,
    pub normalize_logits: bool,
}

impl Default for AdditiveLogits {
    fn default() -> Self {
        Self {
            alpha: 0.0,
            beta: 20.0,
            normalize_logits: false,
        }
    }
}

impl AdditiveLogits {
    /// Compute additive logits from Q, K, and the residue mask.
    ///
    /// $L = QK^\top / \sqrt{d} + \alpha M - \beta(1-M)$
    pub fn compute(
        &self,
        Q: &DMatrix<f64>,
        K: &DMatrix<f64>,
        mask: &ResidueMask,
    ) -> Result<DMatrix<f64>, MaskError> {
        if Q.ncols() != K.ncols() {
            return Err(MaskError::DimensionMismatch {
                q_cols: Q.ncols(),
                k_cols: K.ncols(),
            });
        }
        let d = Q.ncols() as f64;
        let n = Q.nrows();
        if mask.mask.nrows() != n || mask.mask.ncols() != n {
            return Err(MaskError::MaskSizeMismatch {
                mask_n: mask.mask.nrows(),
                mat_n: n,
            });
        }

        // QK^T / sqrt(d)
        let mut L = (Q * K.transpose()) / d.sqrt();

        // Add alpha * M - beta * (1 - M)
        for i in 0..n {
            for j in 0..n {
                let m = mask.mask[(i, j)];
                L[(i, j)] += self.alpha * m - self.beta * (1.0 - m);
            }
        }

        // Optional row normalization
        if self.normalize_logits {
            for i in 0..n {
                let row_max = (0..n).map(|j| L[(i, j)]).fold(f64::NEG_INFINITY, f64::max);
                for j in 0..n {
                    L[(i, j)] -= row_max;
                }
            }
        }

        Ok(L)
    }

    /// Apply row-wise softmax to logits.
    pub fn softmax(&self, L: &DMatrix<f64>) -> DMatrix<f64> {
        let n = L.nrows();
        let m = L.ncols();
        let mut A = DMatrix::<f64>::zeros(n, m);

        for i in 0..n {
            let row_max = (0..m).map(|j| L[(i, j)]).fold(f64::NEG_INFINITY, f64::max);
            let mut sum = 0.0;
            for j in 0..m {
                A[(i, j)] = (L[(i, j)] - row_max).exp();
                sum += A[(i, j)];
            }
            for j in 0..m {
                A[(i, j)] /= sum;
            }
        }
        A
    }
}

/// ε-stabilized Sinkhorn normalization.
///
/// $B = \text{Sinkhorn}(\text{ReLU}(\widetilde{A}) + \varepsilon)$
pub fn sinkhorn_eps(
    A: &DMatrix<f64>,
    config: &SinkhornConfig,
) -> (DMatrix<f64>, f64) {
    let n = A.nrows();
    let m = A.ncols();

    // ReLU + epsilon stabilization
    let mut B = A.map(|x| x.max(0.0) + config.epsilon);

    for _ in 0..config.iters {
        // Row normalization
        for i in 0..n {
            let row_sum: f64 = (0..m).map(|j| B[(i, j)]).sum();
            if row_sum > 0.0 {
                for j in 0..m {
                    B[(i, j)] /= row_sum;
                }
            }
        }

        // Column normalization
        for j in 0..m {
            let col_sum: f64 = (0..n).map(|i| B[(i, j)]).sum();
            if col_sum > 0.0 {
                for i in 0..n {
                    B[(i, j)] /= col_sum;
                }
            }
        }
    }

    // Compute residual
    let mut max_row_resid: f64 = 0.0;
    let mut max_col_resid: f64 = 0.0;
    for i in 0..n {
        let row_sum: f64 = (0..m).map(|j| B[(i, j)]).sum();
        max_row_resid = max_row_resid.max((row_sum - 1.0).abs());
    }
    for j in 0..m {
        let col_sum: f64 = (0..n).map(|i| B[(i, j)]).sum();
        max_col_resid = max_col_resid.max((col_sum - 1.0).abs());
    }
    let resid = max_row_resid.max(max_col_resid);

    (B, resid)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_additive_logits_identity_mask() {
        let n = 4;
        let d = 8.0;
        let Q = DMatrix::<f64>::identity(n, n as usize);
        let K = DMatrix::<f64>::identity(n, n as usize);
        let M = DMatrix::<f64>::identity(n, n);

        let al = AdditiveLogits {
            alpha: 1.0,
            beta: 10.0,
            normalize_logits: false,
        };
        let mask = ResidueMask::from_matrix(M, CrtEmbedding::new(5, 7, n).unwrap());
        let L = al.compute(&Q, &K, &mask).unwrap();

        // Diagonal: 1/sqrt(4) + 1*1 - 10*0 = 1.5
        assert!((L[(0, 0)] - 1.5).abs() < 1e-10);
        // Off-diagonal: 0/sqrt(1) + 1*0 - 10*1 = -10.0
        assert!((L[(0, 1)] - (-10.0)).abs() < 1e-10);
    }

    #[test]
    fn test_softmax_sums_to_one() {
        let n = 5;
        let L = DMatrix::<f64>::from_fn(n, n, |i, j| ((i * n + j) as f64).sin());
        let al = AdditiveLogits::default();
        let A = al.softmax(&L);

        for i in 0..n {
            let row_sum: f64 = (0..n).map(|j| A[(i, j)]).sum();
            assert!((row_sum - 1.0).abs() < 1e-10);
        }
    }

    #[test]
    fn test_sinkhorn_bistochastic() {
        let n = 4;
        let A = DMatrix::<f64>::from_fn(n, n, |i, j| ((i + j) as f64).exp());
        let config = SinkhornConfig::default();
        let (B, resid) = sinkhorn_eps(&A, &config);

        // Row sums should be close to 1
        for i in 0..n {
            let row_sum: f64 = (0..n).map(|j| B[(i, j)]).sum();
            assert!((row_sum - 1.0).abs() < config.tol + 1e-10);
        }
        // Column sums should be close to 1
        for j in 0..n {
            let col_sum: f64 = (0..n).map(|i| B[(i, j)]).sum();
            assert!((col_sum - 1.0).abs() < config.tol + 1e-10);
        }
        assert!(resid < config.tol + 1e-10);
    }

    #[test]
    fn test_mask_nonzero_entries() {
        let crt = CrtEmbedding::new(5, 7, 10).unwrap();
        let mask = ResidueMask::new(crt);
        // Diagonal should be 0 (chi(0) = 0)
        for i in 0..10 {
            assert_eq!(mask.mask[(i, i)], 0.0);
        }
    }
}
