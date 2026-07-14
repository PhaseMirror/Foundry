// src/spectral_resolvent.rs
use crate::hamiltonian::{build_hamiltonians, N_STATES, logN};
use nalgebra::{DMatrix, LU, DVector};
use std::f64;

const KAPPA: f64 = 0.1;
const GAMMA: f64 = 0.5;
const SIGMA: f64 = 2.0;

/// Compute the resolvent matrix (zI - H)^(-1) for a given z and Hamiltonian H.
pub fn resolvent_matrix(z: f64, h: &DMatrix<f64>) -> DMatrix<f64> {
    let n = h.nrows();
    let mut mat = z * DMatrix::identity(n, n) - h.clone();
    let lu = LU::new(mat);
    lu.try_inverse().unwrap_or_else(|| DMatrix::zeros(n, n))
}

/// Compute the trace of the resolvent: Tr[(zI - H)^(-1)].
pub fn resolvent_trace(z: f64, h: &DMatrix<f64>) -> f64 {
    let inv = resolvent_matrix(z, h);
    (0..h.nrows()).map(|i| inv[(i, i)]).sum()
}

/// Analytic first-order expansion of the resolvent trace for H2.
pub fn first_order_trace(z: f64) -> f64 {
    let mut trace = 0.0;
    for i in 0..N_STATES {
        let ln = logN(i);
        let denom = z - ln;
        if denom.abs() > 1e-12 {
            // Free term: 1/(z - ln N)
            trace += 1.0 / denom;
            // First-order correction: κγ * Xi_simple(i,i) / (z - ln N)^2
            let xi = crate::hamiltonian::xi_simple(i, i);
            trace += KAPPA * GAMMA * xi / (denom * denom);
        }
    }
    trace
}


