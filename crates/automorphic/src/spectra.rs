use std::f64::consts::PI;
use nalgebra::DMatrix;
use num_complex::Complex64;
use rand::prelude::*;
use rand_distr::Uniform;

pub fn eigenphases(u: &DMatrix<Complex64>) -> Vec<f64> {
    // eigenvalues of a unitary matrix are on the unit circle: e^(i * theta)
    let eigvals = u.clone().eigenvalues().expect("Eigendecomposition failed");
    eigvals.iter().map(|e| e.arg()).collect()
}

pub fn sato_tate_sample(size: usize) -> Vec<f64> {
    let mut rng = rand::rng();
    let dist = Uniform::new(-PI, PI).unwrap();
    (0..size).map(|_| rng.sample(dist)).collect()
}

pub struct SpectralMetrics {
    pub w1: f64,
    pub ks: f64,
}

pub fn compare_to_st(phases: &[f64]) -> SpectralMetrics {
    let st_sample = sato_tate_sample(phases.len());
    
    // Wasserstein-1 (1D case is the distance between sorted samples)
    let mut p_sorted = phases.to_vec();
    let mut s_sorted = st_sample.clone();
    p_sorted.sort_by(|a, b| a.partial_cmp(b).unwrap());
    s_sorted.sort_by(|a, b| a.partial_cmp(b).unwrap());
    
    let mut w1 = 0.0;
    for (a, b) in p_sorted.iter().zip(s_sorted.iter()) {
        w1 += (a - b).abs();
    }
    w1 /= phases.len() as f64;
    
    // Kolmogorov-Smirnov (2-sample)
    let ks = ks_2sample(&p_sorted, &s_sorted);
    
    SpectralMetrics { w1, ks }
}

fn ks_2sample(data1: &[f64], data2: &[f64]) -> f64 {
    let mut max_diff = 0.0;
    let mut i = 0;
    let mut j = 0;
    
    while i < data1.len() && j < data2.len() {
        let val = data1[i].min(data2[j]);
        while i < data1.len() && data1[i] <= val { i += 1; }
        while j < data2.len() && data2[j] <= val { j += 1; }
        
        let cdf1 = i as f64 / data1.len() as f64;
        let cdf2 = j as f64 / data2.len() as f64;
        let diff = (cdf1 - cdf2).abs();
        if diff > max_diff { max_diff = diff; }
    }
    max_diff
}
