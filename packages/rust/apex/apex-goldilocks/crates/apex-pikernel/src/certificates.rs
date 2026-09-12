use ndarray::{ArrayView1, ArrayView2};
use serde::{Deserialize, Serialize};
use num_traits::{Zero, One, Signed};
use crate::l1proj::Rational;

pub fn slope_upper_bound(alphas: ArrayView1<Rational>, k: ArrayView2<Rational>) -> Rational {
    let m = alphas.len();
    assert_eq!(k.nrows(), m);
    assert_eq!(k.ncols(), m);

    // Compute infinity-norm of A = diag(1-alpha) + diag(alpha)|K|
    let mut max_row_sum = Rational::zero();
    for i in 0..m {
        let mut row_sum = Rational::one() - alphas[i];
        for j in 0..m {
            row_sum = row_sum + (alphas[i] * k[[i, j]].abs());
        }
        if row_sum > max_row_sum {
            max_row_sum = row_sum;
        }
    }

    max_row_sum
}

pub fn gap_lower_bound(slope_ub: Rational) -> Rational {
    Rational::one() - slope_ub
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContractionCertificate {
    pub slope_ub: Rational,
    pub gap_lb: Rational,
    pub is_contractive: bool,
    pub safety_margin: Rational,
}

pub fn verify_contraction(alphas: ArrayView1<Rational>, k: ArrayView2<Rational>) -> ContractionCertificate {
    let slope_ub = slope_upper_bound(alphas, k);
    let gap_lb = gap_lower_bound(slope_ub);
    
    ContractionCertificate {
        slope_ub,
        gap_lb,
        is_contractive: gap_lb > Rational::zero(),
        safety_margin: gap_lb,
    }
}
