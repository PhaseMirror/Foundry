//! Multiplicity Knot Theory (MKT) - Knot Invariants and Protection Factors

use num_complex::Complex64;
use std::f64::consts::PI;
use crate::constants::ALPHA_K;

/// Jones polynomial of the trefoil 3₁: V(t) = −t⁻⁴ + t⁻³ + t⁻¹.
pub fn jones_trefoil(t: Complex64) -> Complex64 {
    -t.powf(-4.0) + t.powf(-3.0) + t.powf(-1.0)
}

/// Jones polynomial of the figure-eight 4₁: V(t) = t⁻² − t⁻¹ + 1 − t + t².
pub fn jones_figure_eight(t: Complex64) -> Complex64 {
    t.powf(-2.0) - t.powf(-1.0) + Complex64::new(1.0, 0.0) - t + t.powf(2.0)
}

/// Jones polynomial of the unknot: V(t) = 1.
pub fn jones_unknot(_t: Complex64) -> Complex64 {
    Complex64::new(1.0, 0.0)
}

pub fn mkt_invariant<F>(jones_fn: F, s: Complex64) -> Complex64 
where F: Fn(Complex64) -> Complex64 {
    // Evaluate Jones polynomial at t = exp(2πi * s)
    let t = (Complex64::i() * 2.0 * PI * s).exp();
    let jones_value = jones_fn(t);

    // Apply phase correction using universal constant ALPHA_K
    let phase_factor = (Complex64::i() * ALPHA_K).exp();

    jones_value * phase_factor
}

pub fn compute_protection_factor(c_zero: f64, crossing_number: u32) -> f64 {
    (c_zero * crossing_number as f64).exp()
}
