use std::f64::consts::PI;
use nalgebra::{DMatrix, DVector};
use num_complex::Complex64;

pub struct UnitaryResult {
    pub u: DMatrix<Complex64>,
    pub path: String,
    pub residual: f64,
}

pub fn exp_unitary(b: &DMatrix<f64>) -> UnitaryResult {
    let n = b.nrows();
    let j = DMatrix::from_element(n, n, 1.0 / n as f64);
    let h = (b - j) * PI;
    
    // exp(i * H)
    // For symmetric H, H = Q D Q^T, exp(i H) = Q exp(i D) Q^T
    // Since H = PI * (B - J) and B, J are doubly stochastic (assuming B is symmetric), H is symmetric.
    let eig = h.symmetric_eigen();
    let q = eig.eigenvectors;
    let d = eig.eigenvalues;
    
    let exp_id_diag = DVector::from_iterator(n, d.iter().map(|&val| Complex64::from_polar(1.0, val)));
    let exp_id = DMatrix::from_diagonal(&exp_id_diag);
    
    let q_complex = q.map(|val| Complex64::new(val, 0.0));
    let u = &q_complex * exp_id * q_complex.adjoint();
    
    // Unitarity residual: ||U*U^H - I||
    let identity = DMatrix::identity(n, n);
    let res_mat = &u * u.adjoint() - identity.map(|val| Complex64::new(val, 0.0));
    let residual = res_mat.norm();
    
    UnitaryResult { u, path: "exp".to_string(), residual }
}

pub fn cayley_unitary(b: &DMatrix<f64>) -> UnitaryResult {
    let n = b.nrows();
    let s = (b - b.transpose()) * 0.5;
    
    let identity = DMatrix::identity(n, n);
    let i_minus_s = &identity - &s;
    let i_plus_s = &identity + &s;
    
    match i_plus_s.try_inverse() {
        Some(inv) => {
            let u_real = i_minus_s * inv;
            let u = u_real.map(|val| Complex64::new(val, 0.0));
            
            let res_mat = &u_real * u_real.transpose() - &identity;
            let residual = res_mat.norm();
            
            UnitaryResult { u, path: "cayley".to_string(), residual }
        }
        None => exp_unitary(b),
    }
}
