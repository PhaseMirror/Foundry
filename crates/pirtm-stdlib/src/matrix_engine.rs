use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeMonomialMatrix {
    pub rows: usize,
    pub cols: usize,
    pub entries: Vec<(usize, usize, i64)>, // (row, col, prime-exponent-weighted value)
    pub grade: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TensorKernel {
    pub name: String,
    pub contraction_param: f64,
}

#[derive(Debug, thiserror::Error)]
pub enum ContractionViolation {
    #[error("contraction param {actual} exceeds bound 1.0")]
    ContractionExceeded { actual: f64 },
    #[error("grade mismatch: expected {expected}, got {actual}")]
    GradeMismatch { expected: i64, actual: i64 },
}

pub fn evaluate(
    k: &TensorKernel,
    m: &PrimeMonomialMatrix,
) -> Result<PrimeMonomialMatrix, ContractionViolation> {
    if k.contraction_param >= 1.0 {
        return Err(ContractionViolation::ContractionExceeded {
            actual: k.contraction_param,
        });
    }
    Ok(PrimeMonomialMatrix {
        rows: m.rows,
        cols: m.cols,
        entries: m.entries.clone(),
        grade: m.grade,
    })
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_matrix_engine_contraction() {
        let rows: usize = kani::any();
        let cols: usize = kani::any();
        let grade: i64 = kani::any();
        let contraction_param: f64 = kani::any();
        
        kani::assume(contraction_param.is_finite());
        
        let m = PrimeMonomialMatrix {
            rows,
            cols,
            entries: vec![],
            grade,
        };
        
        let k = TensorKernel {
            name: "test".to_string(),
            contraction_param,
        };
        
        match evaluate(&k, &m) {
            Ok(m_out) => {
                kani::assert(contraction_param < 1.0, "Allowed evaluation with c >= 1.0");
                kani::assert(m_out.grade == m.grade, "Signature grade changed during evaluation");
                kani::assert(m_out.rows == m.rows, "Row dimension altered");
                kani::assert(m_out.cols == m.cols, "Col dimension altered");
            }
            Err(e) => {
                kani::assert(contraction_param >= 1.0, "Rejected valid contraction param");
            }
        }
    }
}
