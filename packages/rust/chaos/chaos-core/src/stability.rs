use nalgebra::DMatrix;

pub fn phi(z: f64) -> f64 {
    if z > 50.0 {
        z
    } else {
        (1.0 + z.exp()).ln()
    }
}

pub fn v_lyapunov(r_val: f64) -> f64 {
    phi(-r_val)
}

pub fn check_fejer_monotonicity(v_prev: f64, v_next: f64, tol: f64) -> bool {
    (v_next - v_prev) <= tol
}

pub fn check_spectral_radius(matrix: &DMatrix<f64>, eta: f64) -> bool {
    // Assuming real eigenvalues for now based on compiler error
    let eigen = matrix.eigenvalues().expect("Eigenvalue calculation failed");
    let max_rho = eigen.iter().map(|e| e.abs()).fold(0.0f64, |a, b| a.max(b));
    max_rho <= (1.0 - eta)
}
