use num_complex::Complex64;
use nalgebra::{MatrixN, Dim, DefaultAllocator, allocator::Allocator};
use std::f64::consts::PI;

/// Unitarize a square matrix using the matrix exponential.
/// For simplicity we restrict to 2×2 matrices (Dim = U2).
pub fn unitarize_exp<B>(b: &MatrixN<Complex64, nalgebra::U2>) -> MatrixN<Complex64, nalgebra::U2>
where
    DefaultAllocator: Allocator<Complex64, nalgebra::U2, nalgebra::U2>,
{
    // Use nalgebra's matrix exponential (via the `exp` method).
    b.exp()
}

#[cfg(test)]
mod tests {
    use super::*;
    use nalgebra::matrix!
    ;
    #[kani::proof]
    fn test_unitarize_exp_is_unitary() {
        // Simple Hermitian matrix
        let b = matrix![Complex64::new(0.0, 0.0), Complex64::new(0.0, 1.0);
                        Complex64::new(0.0, -1.0), Complex64::new(0.0, 0.0)];
        let u = unitarize_exp(&b);
        // Verify U * U^† = I (within tolerance)
        let id = MatrixN::<Complex64, nalgebra::U2>::identity();
        let prod = &u * &u.adjoint();
        for i in 0..2 {
            for j in 0..2 {
                let diff = (prod[(i, j)] - id[(i, j)]).norm();
                assert!(diff < 1e-6);
            }
        }
    }
}
