//! Algebraic Jury stability criteria for 2×2 and 3×3 **nonnegative** matrices.
//!
//! The Schur-implies-contractivity lemmas verified by Kani require the matrix
//! entries to be nonnegative; counterexamples exist for sign-indefinite
//! matrices. All operators built from the prime-indexed construction (A_p)
//! satisfy this hypothesis.

use ndarray::{Array1, Array2};

/// Check if there exists a positive vector v (all entries > 0) such that
/// A * v < v component‑wise (strict inequality).
pub fn satisfies_schur_condition(a: &Array2<f64>, v: &Array1<f64>) -> bool {
    let av = a.dot(v);
    av.iter()
        .zip(v.iter())
        .all(|(av_i, v_i)| av_i < v_i)
        && v.iter().all(|&x| x > 0.0)
}

// ── 2×2 Jury stability criterion ──────────────────────────────────
// A 2×2 real matrix has all eigenvalues inside the unit circle iff:
//   |det(A)| < 1   and   |tr(A)| < 1 + det(A)
pub fn spectral_radius_less_than_one_2x2(a: &Array2<f64>) -> bool {
    let tr = a[[0, 0]] + a[[1, 1]];
    let det = a[[0, 0]] * a[[1, 1]] - a[[0, 1]] * a[[1, 0]];
    let eps = 1e-9;
    det.abs() < 1.0 + eps && tr.abs() < 1.0 + det + eps
}

// ── 3×3 Jury stability criterion ──────────────────────────────────
// For a 3×3 real matrix with characteristic polynomial
//   P(z) = z³ + c₂ z² + c₁ z + c₀
// (monic, i.e. coefficient of z³ is 1).  The Jury table gives three
// necessary and sufficient conditions for all roots to lie inside the
// unit circle:
//   (i)   P(1) > 0
//   (ii)  (-1)³ P(-1) > 0   (i.e. -P(-1) > 0)
//   (iii) |c₀| < 1,  |c₁ - c₀ c₂| < |1 - c₀²|
pub fn spectral_radius_less_than_one_3x3(a: &Array2<f64>) -> bool {
    // compute coefficients of characteristic polynomial
    let tr = a[[0, 0]] + a[[1, 1]] + a[[2, 2]];
    // sum of principal minors of order 2
    let m01 = a[[0,0]]*a[[1,1]] - a[[0,1]]*a[[1,0]];
    let m02 = a[[0,0]]*a[[2,2]] - a[[0,2]]*a[[2,0]];
    let m12 = a[[1,1]]*a[[2,2]] - a[[1,2]]*a[[2,1]];
    let sum_2 = m01 + m02 + m12;
    let det = a[[0,0]]*m12 - a[[0,1]]*(a[[1,0]]*a[[2,2]] - a[[1,2]]*a[[2,0]])
              + a[[0,2]]*(a[[1,0]]*a[[2,1]] - a[[1,1]]*a[[2,0]]);
    // coefficients: P(z) = z³ - tr*z² + sum_2*z - det  (when matrix is 3x3)
    let c2 = -tr;
    let c1 = sum_2;
    let c0 = -det;

    // Condition (i): P(1) = 1 + c2 + c1 + c0 > 0
    let p1 = 1.0 + c2 + c1 + c0;
    // Condition (ii): (-1)^3 P(-1) = -P(-1) > 0  =>  P(-1) < 0
    let p_neg1 = -1.0 + c2 - c1 + c0;
    // Condition (iii): |c0| < 1  and  |c1 - c0*c2| < |1 - c0*c0|
    let cond3 = c0.abs() < 1.0 && (c1 - c0 * c2).abs() < (1.0 - c0 * c0).abs();
    p1 > 0.0 && p_neg1 < 0.0 && cond3
}
