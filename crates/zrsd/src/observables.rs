use nalgebra::DMatrix;
use num_complex::Complex64;

pub fn expectation(rho: &DMatrix<Complex64>, a: &DMatrix<Complex64>) -> f64 {
    (rho * a).trace().re
}

pub fn purity(rho: &DMatrix<Complex64>) -> f64 {
    (rho * rho).trace().re
}

pub fn entropy_vn(rho: &DMatrix<Complex64>) -> f64 {
    // S = -Tr(rho log rho)
    let eig = rho.clone().eigenvalues().expect("Eigendecomposition failed");
    let mut entropy = 0.0;
    for &p in eig.iter() {
        let p_re = p.re;
        if p_re > 1e-12 {
            entropy -= p_re * p_re.ln();
        }
    }
    entropy
}
