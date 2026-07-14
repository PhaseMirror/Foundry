use crate::hamiltonian::{xi_simple, N_STATES};
use nalgebra::DMatrix;

pub fn trace_delta_h(h1: &DMatrix<f64>, h2: &DMatrix<f64>) -> f64 {
    (0..N_STATES).map(|i| h2[(i, i)] - h1[(i, i)]).sum()
}

pub fn diag_perturbation(kappa: f64, gamma: f64, _sigma: f64, i: usize) -> f64 {
    // Diagonal of the interaction: kappa * gamma * Xi_simple(i,i)
    kappa * gamma * xi_simple(i, i)
}

pub fn formal_correlation(delta_e: &[f64], kappa: f64, gamma: f64, sigma: f64) -> f64 {
    let n = delta_e.len() as f64;
    let diag_vals: Vec<f64> = (0..delta_e.len())
        .map(|i| diag_perturbation(kappa, gamma, sigma, i))
        .collect();

    let mean_d = delta_e.iter().sum::<f64>() / n;
    let mean_s = diag_vals.iter().sum::<f64>() / n;

    let cov = delta_e.iter().zip(&diag_vals)
        .map(|(d, s)| (d - mean_d) * (s - mean_s))
        .sum::<f64>() / n;

    let var_d = delta_e.iter().map(|d| (d - mean_d).powi(2)).sum::<f64>() / n;
    let var_s = diag_vals.iter().map(|s| (s - mean_s).powi(2)).sum::<f64>() / n;

    if var_d * var_s == 0.0 { 0.0 } else { cov / (var_d * var_s).sqrt() }
}
