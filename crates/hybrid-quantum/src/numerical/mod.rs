use faer::{Mat, Side};
use nalgebra::DMatrix;

/// Compute the eigenvalues of a real symmetric matrix using faer.
///
/// This function converts the nalgebra matrix to a faer matrix, performs
/// symmetric eigenvalue decomposition, and returns the eigenvalues sorted
/// in descending order by absolute value.
///
/// For non-symmetric matrices, the function computes the eigenvalues of
/// the symmetric part (A + A^T) / 2, which provides the spectral bounds
/// relevant to PIRTM stability analysis.
pub fn compute_eigenvalues(matrix: &DMatrix<f64>) -> Vec<f64> {
    let dim = matrix.nrows();
    if dim == 0 {
        return Vec::new();
    }

    // Symmetrize: compute (A + A^T) / 2 for spectral analysis.
    // The symmetric part captures the contractive/expansive behavior.
    let sym = Mat::from_fn(dim, dim, |i, j| {
        (matrix[(i, j)] + matrix[(j, i)]) / 2.0
    });

    // Perform eigendecomposition using faer's self-adjoint eigensolver.
    // `Side::Lower` tells faer to read the lower triangle (sufficient for symmetric).
    // The result is sorted in nondecreasing order by faer.
    match sym.self_adjoint_eigen(Side::Lower) {
        Ok(eig) => {
            // eig.values is a Diag containing the eigenvalues on its diagonal.
            let mut eigenvalues: Vec<f64> = eig.S().column_vector().iter().copied().collect();
            // Sort by absolute value descending for spectral radius analysis.
            eigenvalues.sort_by(|a, b| b.abs().partial_cmp(&a.abs()).unwrap_or(std::cmp::Ordering::Equal));
            eigenvalues
        }
        Err(_) => {
            // Fallback: return zeros if decomposition fails (singular/degenerate matrix).
            vec![0.0; dim]
        }
    }
}

/// Approximate the spectral radius of a matrix.
///
/// The spectral radius is the maximum absolute value of any eigenvalue.
/// This is the critical quantity for PIRTM stability invariants (I1-I4):
/// - I1: spectral radius < 1.0 (contractivity)
/// - I2: spectral radius bounded away from 1.0 (robust contractivity)
/// - I3: spectral radius monotone decreasing under composition
/// - I4: spectral radius consistent across prime-indexed decompositions
pub fn spectral_radius_approximation(matrix: &DMatrix<f64>) -> f64 {
    let eigenvalues = compute_eigenvalues(matrix);
    eigenvalues.iter()
        .map(|e| e.abs())
        .fold(0.0_f64, f64::max)
}

#[cfg(test)]
mod tests {
    use super::*;
    use nalgebra::DMatrix;

    #[test]
    fn test_identity_matrix() {
        let m = DMatrix::<f64>::identity(3, 3);
        let eigenvalues = compute_eigenvalues(&m);
        assert_eq!(eigenvalues.len(), 3);
        // All eigenvalues of identity are 1.0
        for ev in &eigenvalues {
            assert!((ev - 1.0).abs() < 1e-10);
        }
        assert!((spectral_radius_approximation(&m) - 1.0).abs() < 1e-10);
    }

    #[test]
    fn test_diagonal_contractive() {
        // Diagonal matrix with entries < 1.0 — should be contractive
        let m = DMatrix::from_diagonal(&nalgebra::DVector::from_vec(vec![0.5, 0.3, 0.7]));
        let sr = spectral_radius_approximation(&m);
        assert!(sr < 1.0, "Expected contractive, got spectral radius {}", sr);
        assert!((sr - 0.7).abs() < 1e-10);
    }

    #[test]
    fn test_diagonal_expansive() {
        // Diagonal matrix with entries > 1.0 — should be non-contractive
        let m = DMatrix::from_diagonal(&nalgebra::DVector::from_vec(vec![0.5, 1.2, 0.3]));
        let sr = spectral_radius_approximation(&m);
        assert!(sr >= 1.0, "Expected non-contractive, got spectral radius {}", sr);
        assert!((sr - 1.2).abs() < 1e-10);
    }

    #[test]
    fn test_symmetric_2x2() {
        // [[0.6, 0.2], [0.2, 0.6]] — eigenvalues are 0.8 and 0.4
        let m = DMatrix::from_row_slice(2, 2, &[0.6, 0.2, 0.2, 0.6]);
        let mut eigenvalues = compute_eigenvalues(&m);
        eigenvalues.sort_by(|a, b| b.partial_cmp(a).unwrap());
        assert!((eigenvalues[0] - 0.8).abs() < 1e-10);
        assert!((eigenvalues[1] - 0.4).abs() < 1e-10);
        assert!((spectral_radius_approximation(&m) - 0.8).abs() < 1e-10);
    }

    #[test]
    fn test_empty_matrix() {
        let m = DMatrix::<f64>::zeros(0, 0);
        let eigenvalues = compute_eigenvalues(&m);
        assert!(eigenvalues.is_empty());
    }
}
