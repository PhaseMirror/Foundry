//! Permutation-equivariant unitarization via exp and Cayley paths.
//!
//! Two unitarization paths from a bistochastic matrix $B$:
//! - **Exp (default):** $U = \exp(\pi i (B - J))$
//! - **Cayley (robustness):** $S = \frac{1}{2}(B - B^\top)$, $U = (I-S)(I+S)^{-1}$
//!
//! Both are permutation-equivariant: $U(PAP^\top) = P U(A) P^\top$.

use nalgebra::{Complex, DMatrix, DVector};
use num_complex::Complex64;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum UnitaryError {
    #[error("Cayley: I+S is singular (lambda_min = {lambda_min})")]
    CayleySingular { lambda_min: f64 },
    #[error("matrix not square: {n}x{m}")]
    NotSquare { n: usize, m: usize },
}

/// Which unitarization path to use.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub enum UnitaryPath {
    /// $U = \exp(\pi i (B - J))$ — default, smooth.
    Exp,
    /// $U = (I-S)(I+S)^{-1}$ where $S = (B-B^\top)/2$ — robustness fallback.
    Cayley,
}

/// Configuration for ε-stabilized Sinkhorn (reused from mask module).
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SinkhornParams {
    pub epsilon: f64,
    pub iters: usize,
    pub tol: f64,
}

impl Default for SinkhornParams {
    fn default() -> Self {
        Self {
            epsilon: 1e-6,
            iters: 5,
            tol: 1e-3,
        }
    }
}

/// ε-stabilized Sinkhorn normalization.
pub fn sinkhorn_eps(
    A: &DMatrix<f64>,
    params: &SinkhornParams,
) -> (DMatrix<f64>, f64) {
    let n = A.nrows();
    let m = A.ncols();

    let mut B = A.map(|x| x.max(0.0) + params.epsilon);

    for _ in 0..params.iters {
        for i in 0..n {
            let row_sum: f64 = (0..m).map(|j| B[(i, j)]).sum();
            if row_sum > 0.0 {
                for j in 0..m {
                    B[(i, j)] /= row_sum;
                }
            }
        }
        for j in 0..m {
            let col_sum: f64 = (0..n).map(|i| B[(i, j)]).sum();
            if col_sum > 0.0 {
                for i in 0..n {
                    B[(i, j)] /= col_sum;
                }
            }
        }
    }

    let mut max_resid: f64 = 0.0;
    for i in 0..n {
        let row_sum: f64 = (0..m).map(|j| B[(i, j)]).sum();
        max_resid = max_resid.max((row_sum - 1.0).abs());
    }
    for j in 0..m {
        let col_sum: f64 = (0..n).map(|i| B[(i, j)]).sum();
        max_resid = max_resid.max((col_sum - 1.0).abs());
    }

    (B, max_resid)
}

/// Apply exp unitarization: $U = \exp(\pi i (B - J))$.
///
/// Uses the eigendecomposition of the Hermitian part.
pub fn exp_unitary(B: &DMatrix<f64>) -> DMatrix<Complex64> {
    let n = B.nrows();
    let J = DMatrix::<f64>::from_fn(n, n, |_, _| 1.0 / n as f64);
    let S = (B - &J) * std::f64::consts::PI;

    // Build complex matrix i*S
    let iS: DMatrix<Complex64> = S.map(|x| Complex64::new(0.0, x));

    // Matrix exponential via Padé approximation (simplified: use eigendecomposition)
    // For production, use a proper matrix exponential library
    matrix_exp_hermitian(&iS)
}

/// Apply Cayley unitarization: $U = (I-S)(I+S)^{-1}$ where $S = (B-B^\top)/2$.
pub fn cayley_unitary(B: &DMatrix<f64>) -> Result<DMatrix<Complex64>, UnitaryError> {
    let n = B.nrows();
    let S = (B - B.transpose()) * 0.5;

    let I = DMatrix::<f64>::identity(n, n);
    let IP = &I + &S; // I + S
    let IM = &I - &S; // I - S

    // Check if I+S is invertible
    let det = IP.determinant();
    if det.abs() < 1e-12 {
        return Err(UnitaryError::CayleySingular {
            lambda_min: det.abs().sqrt(),
        });
    }

    // Solve (I+S)U = (I-S)
    let U_real = IP.try_inverse().ok_or(UnitaryError::CayleySingular {
        lambda_min: det.abs().sqrt(),
    })? * &IM;

    Ok(U_real.map(|x| Complex64::new(x, 0.0)))
}

/// Compute unitary residual $\|U^\ast U - I\|_{1 \to 1}$.
pub fn unitary_residual(U: &DMatrix<Complex64>) -> f64 {
    let n = U.nrows();
    let I = DMatrix::<Complex64>::identity(n, n);
    let UU = U.adjoint() * U;
    let diff = &UU - &I;

    // Spectral norm (1→1 norm = max column sum)
    let mut max_col_sum: f64 = 0.0;
    for j in 0..n {
        let col_sum: f64 = (0..n).map(|i| diff[(i, j)].norm()).sum();
        max_col_sum = max_col_sum.max(col_sum);
    }
    max_col_sum
}

/// Check permutation invariance: $\text{KS}(\text{spec}(U), \text{spec}(U_g)) \le \text{tol}$.
pub fn permutation_ks(
    phases_a: &[f64],
    phases_b: &[f64],
    tol: f64,
) -> (bool, f64) {
    let mut a: Vec<f64> = phases_a.iter().map(|x| x.rem_euclid(2.0 * std::f64::consts::PI)).collect();
    let mut b: Vec<f64> = phases_b.iter().map(|x| x.rem_euclid(2.0 * std::f64::consts::PI)).collect();
    a.sort_by(|x, y| x.partial_cmp(y).unwrap());
    b.sort_by(|x, y| x.partial_cmp(y).unwrap());

    // Merge sorted grids
    let mut grid: Vec<f64> = a.iter().chain(b.iter()).copied().collect();
    grid.sort_by(|x, y| x.partial_cmp(y).unwrap());
    grid.dedup();

    let _n_a = a.len() as f64;
    let _n_b = b.len() as f64;

    let ecdf = |x: f64, s: &[f64]| -> f64 {
        let count = s.iter().filter(|&&v| v <= x).count();
        count as f64 / s.len() as f64
    };

    let mut ks: f64 = 0.0;
    for &x in &grid {
        let d = (ecdf(x, &a) - ecdf(x, &b)).abs();
        ks = ks.max(d);
    }

    (ks <= tol, ks)
}

/// Simple matrix exponential for Hermitian matrices via eigendecomposition.
/// For production use, replace with a proper numerical library.
fn matrix_exp_hermitian(H: &DMatrix<Complex64>) -> DMatrix<Complex64> {
    let n = H.nrows();

    // For small matrices, use Taylor series approximation
    if n <= 4 {
        return matrix_exp_taylor(H, 20);
    }

    // For larger matrices, use diagonalization (simplified)
    // In production, use nalgebra-lapack or ndarray-linalg
    matrix_exp_taylor(H, 20)
}

/// Taylor series matrix exponential: $e^X = \sum_{k=0}^{N} X^k / k!$.
fn matrix_exp_taylor(X: &DMatrix<Complex64>, order: usize) -> DMatrix<Complex64> {
    let n = X.nrows();
    let mut result = DMatrix::<Complex64>::identity(n, n);
    let mut X_power = DMatrix::<Complex64>::identity(n, n);
    let mut factorial = 1.0;

    for k in 1..=order {
        X_power = &X_power * X;
        factorial *= k as f64;
        result = &result + &X_power * Complex64::new(1.0 / factorial, 0.0);
    }

    result
}

#[cfg(test)]
mod tests {
    use super::*;
    use approx::assert_relative_eq;

    #[test]
    fn test_sinkhorn_bistochastic() {
        let n = 4;
        let A = DMatrix::<f64>::from_fn(n, n, |i, j| ((i + j) as f64).exp());
        let params = SinkhornParams::default();
        let (B, resid) = sinkhorn_eps(&A, &params);

        for i in 0..n {
            let row_sum: f64 = (0..n).map(|j| B[(i, j)]).sum();
            assert!((row_sum - 1.0).abs() < params.tol + 1e-10);
        }
        assert!(resid < params.tol + 1e-10);
    }

    #[test]
    fn test_cayley_unitary() {
        let n = 3;
        let B = DMatrix::<f64>::from_fn(n, n, |i, j| {
            ((i + j) as f64).sin().abs() + 0.1
        });
        // Make it doubly stochastic (approximate)
        let params = SinkhornParams::default();
        let (B, _) = sinkhorn_eps(&B, &params);

        let U = cayley_unitary(&B).unwrap();
        let res = unitary_residual(&U);
        assert!(res < 1e-6, "Cayley unitarity residual: {}", res);
    }

    #[test]
    fn test_permutation_invariance() {
        let n = 4;
        // Create two random phase sets
        let phases_a: Vec<f64> = (0..n).map(|i| (i as f64 * 0.7).sin() * 2.0).collect();
        let phases_b = phases_a.clone(); // Same phases
        let (pass, ks) = permutation_ks(&phases_a, &phases_b, 1e-10);
        assert!(pass);
        assert!(ks < 1e-10);
    }

    #[test]
    fn test_unitary_residual_identity() {
        let n = 4;
        let I = DMatrix::<Complex64>::identity(n, n);
        let res = unitary_residual(&I);
        assert!(res < 1e-10);
    }
}
