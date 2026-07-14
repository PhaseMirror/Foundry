pub use crate::generated_vals_array::{N_STATES, PRIMES, VALS};
use nalgebra::{DMatrix, DVector};
use num::integer::gcd;

pub fn number_of_state(idx: usize) -> u32 {
    let mut n = 1;
    for (p, &e) in PRIMES.iter().zip(&VALS[idx]) {
        n *= p.pow(e as u32);
    }
    n
}

pub fn logN(idx: usize) -> f64 {
    (number_of_state(idx) as f64).ln()
}

pub fn gcd_log(i: usize, j: usize) -> f64 {
    let a = number_of_state(i);
    let b = number_of_state(j);
    let g = gcd(a, b);
    if g == 1 { 0.0 } else { (g as f64).ln() }
}

pub fn xi_simple(i: usize, j: usize) -> f64 {
    let mut sum = 0i32;
    let mut sum_sq = 0i32;
    for k in 0..PRIMES.len() {
        let alpha = VALS[i][k].min(VALS[j][k]);
        sum += alpha as i32;
        sum_sq += (alpha * alpha) as i32;
    }
    (sum * sum - sum_sq) as f64
}

pub fn build_hamiltonians(kappa: f64, gamma: f64, sigma: f64) -> (DMatrix<f64>, DMatrix<f64>) {
    let mut h1 = DMatrix::zeros(N_STATES, N_STATES);
    let mut h2 = DMatrix::zeros(N_STATES, N_STATES);

    for i in 0..N_STATES {
        for j in 0..N_STATES {
            let d = logN(i) - logN(j);
            let w = (-d * d / (2.0 * sigma * sigma)).exp();
            let kg = gcd_log(i, j);
            let xi = xi_simple(i, j);

            let h1_val = if i == j { logN(i) } else { 0.0 } + kappa * (kg * w);
            let h2_val = h1_val + kappa * gamma * (xi * w);

            h1[(i, j)] = h1_val;
            h2[(i, j)] = h2_val;
        }
    }
    (h1, h2)
}
