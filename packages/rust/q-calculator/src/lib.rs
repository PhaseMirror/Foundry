#[cfg(target_arch = "wasm32")]
pub mod wasm;

use serde::{Deserialize, Serialize};
use nalgebra::{DMatrix, DVector};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum QAriError {
    #[error("Dimension mismatch: expected {expected}, found {found}")]
    DimensionMismatch { expected: usize, found: usize },
    #[error("Contractivity violation: q_t {q_t} > target {target}")]
    ContractivityViolation { q_t: f64, target: f64 },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QAriParams {
    pub epsilon: f64,
    pub op_norm_t: f64,
    pub max_steps: usize,
    pub tol: f64,
}

impl Default for QAriParams {
    fn default() -> Self {
        QAriParams {
            epsilon: 0.05,
            op_norm_t: 1.0,
            max_steps: 200,
            tol: 1e-6,
        }
    }
}

pub struct QAriCore<T>
where
    T: Fn(&DVector<f64>) -> DVector<f64>,
{
    pub t_op: T,
    pub params: QAriParams,
}

impl<T> QAriCore<T>
where
    T: Fn(&DVector<f64>) -> DVector<f64>,
{
    pub fn new(t_op: T, params: Option<QAriParams>) -> Self {
        QAriCore {
            t_op,
            params: params.unwrap_or_default(),
        }
    }

    pub fn step(
        &self,
        x_t: &DVector<f64>,
        xi_t: &DMatrix<f64>,
        lam_t: &DMatrix<f64>,
        g_t: &DVector<f64>,
    ) -> Result<DVector<f64>, QAriError> {
        // Calculate q_t
        let n_xi = xi_t.norm(); // Using Frobenius norm as a placeholder for op_norm
        let n_lam = lam_t.norm();
        let q_t = n_xi + n_lam * self.params.op_norm_t;
        let target = 1.0 - self.params.epsilon;

        if q_t > target {
            // In a real implementation, we'd project weights here
            return Err(QAriError::ContractivityViolation { q_t, target });
        }

        // X_{t+1} = Ξ(t) X_t + Λ(t) T(X_t) + G_t
        let tx_t = (self.t_op)(x_t);
        let x_next = xi_t * x_t + lam_t * tx_t + g_t;

        Ok(x_next)
    }

    pub fn run(
        &self,
        x0: DVector<f64>,
        xi_seq: &[DMatrix<f64>],
        lam_seq: &[DMatrix<f64>],
        g_seq: &[DVector<f64>],
    ) -> Result<(DVector<f64>, Vec<DVector<f64>>), QAriError> {
        let mut x = x0;
        let mut history = vec![x.clone()];
        let t_max = xi_seq.len().min(lam_seq.len()).min(g_seq.len()).min(self.params.max_steps);

        for t in 0..t_max {
            let x_next = self.step(&x, &xi_seq[t], &lam_seq[t], &g_seq[t])?;
            let resid = (&x_next - &x).norm();
            history.push(x_next.clone());
            x = x_next;

            if resid < self.params.tol {
                break;
            }
        }

        Ok((x, history))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_q_ari_step() {
        let t_op = |x: &DVector<f64>| x * 0.75;
        let core = QAriCore::new(t_op, None);
        
        let x_t = DVector::from_vec(vec![1.0, 1.0]);
        let xi_t = DMatrix::from_diagonal(&DVector::from_vec(vec![0.1, 0.1]));
        let lam_t = DMatrix::from_diagonal(&DVector::from_vec(vec![0.1, 0.1]));
        let g_t = DVector::from_vec(vec![0.0, 0.0]);
        
        let result = core.step(&x_t, &xi_t, &lam_t, &g_t);
        assert!(result.is_ok());
    }
}
