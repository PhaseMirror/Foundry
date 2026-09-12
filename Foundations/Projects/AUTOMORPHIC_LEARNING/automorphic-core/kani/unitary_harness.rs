//! Kani harnesses for unitary module.
//!
//! Run with: kani kani/unitary_harness.rs

use automorphic_core::unitary::{exp_unitary, cayley_unitary, unitary_residual};
use nalgebra::DMatrix;
use num_complex::Complex;

#[kani::proof]
fn check_exp_unitary_output_shape() {
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 10);
    
    let mut B = DMatrix::<f64>::zeros(n, n);
    for i in 0..n {
        for j in 0..n {
            let val: f64 = kani::any();
            B[(i, j)] = val;
        }
    }
    
    let U = exp_unitary(&B);
    assert_eq!(U.nrows(), n);
    assert_eq!(U.ncols(), n);
}

#[kani::proof]
fn check_exp_unitary_deterministic() {
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 10);
    
    let mut B = DMatrix::<f64>::zeros(n, n);
    for i in 0..n {
        for j in 0..n {
            let val: f64 = kani::any();
            B[(i, j)] = val;
        }
    }
    
    let U1 = exp_unitary(&B);
    let U2 = exp_unitary(&B);
    
    for i in 0..n {
        for j in 0..n {
            assert!((U1[(i, j)] - U2[(i, j)]).abs() < 1e-10);
        }
    }
}

#[kani::proof]
fn check_unitary_residual_bounded() {
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 10);
    
    let mut B = DMatrix::<f64>::zeros(n, n);
    for i in 0..n {
        for j in 0..n {
            let val: f64 = kani::any();
            B[(i, j)] = val;
        }
    }
    
    let U = exp_unitary(&B);
    let res = unitary_residual(&U);
    
    // Residual should be non-negative
    assert!(res >= 0.0);
    
    // Residual should be bounded by n (trivial bound)
    assert!(res <= n as f64 + 1e-6);
}
