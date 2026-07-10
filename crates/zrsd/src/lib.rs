pub mod core;
pub mod algebra;
pub mod speculative;
pub mod observables;

pub use crate::core::{get_prime_factors, PrimeAnchor};
pub use crate::speculative::{lindblad_rhs, euler_step, rk4_step, get_h_zeta, evaluate_zrsd_step, ZrsdCertificate};
pub use crate::observables::{expectation, purity, entropy_vn};
pub use crate::algebra::{get_binary_basis, get_creation_annihilation, multiplicity_operator};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_multiplicity_operator() {
        let primes = vec![2, 3];
        let basis = get_binary_basis(2);
        let m = multiplicity_operator(&primes, &basis);
        assert_eq!(m.nrows(), 4);
        
        let diag = m.diagonal();
        assert!((diag[0].re - 0.0).abs() < 1e-10);
        assert!((diag[1].re - 3.0f64.ln()).abs() < 1e-10);
        assert!((diag[2].re - 2.0f64.ln()).abs() < 1e-10);
        assert!((diag[3].re - 6.0f64.ln()).abs() < 1e-10);
    }

    #[test]
    fn test_euler_step() {
        use nalgebra::{DMatrix, DVector};
        use num_complex::Complex64;
        let rho = DMatrix::from_diagonal(&DVector::from_vec(vec![Complex64::new(1.0, 0.0), Complex64::new(0.0, 0.0)]));
        let h = DMatrix::from_element(2, 2, Complex64::new(0.0, 0.0));
        let ls = vec![];
        let rho_next = euler_step(&rho, &h, &ls, 0.1);
        assert!((rho_next.trace().re - 1.0).abs() < 1e-10);
    }

    #[test]
    fn test_evaluate_zrsd_step() {
        use nalgebra::{DMatrix, DVector};
        use num_complex::Complex64;
        let psi = DVector::from_vec(vec![Complex64::new(1.0, 0.0), Complex64::new(0.0, 0.0)]);
        let g_base = DMatrix::identity(2, 2) * Complex64::new(0.4, 0.0);
        let r_zeta = DMatrix::zeros(2, 2);
        let (psi_next, cert) = evaluate_zrsd_step(&psi, &g_base, 0.75, &r_zeta, 0.01);
        assert!(cert.is_admissible);
        assert!((psi_next.norm() - 1.0).abs() < 1e-10);
    }
}
