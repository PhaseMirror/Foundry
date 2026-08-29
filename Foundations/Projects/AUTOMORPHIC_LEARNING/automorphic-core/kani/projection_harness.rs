//! Kani harnesses for projection module.
//!
//! Run with: kani kani/projection_harness.rs

use automorphic_core::projection::{project_weighted_l1, softmax_ub, slopeub};

#[kani::proof]
fn check_projection_feasible() {
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 10);
    
    let mut v = Vec::with_capacity(n);
    let mut omega = Vec::with_capacity(n);
    
    for _ in 0..n {
        let vi: f64 = kani::any();
        let oi: f64 = kani::any();
        kani::assume(oi > 0.0);
        v.push(vi);
        omega.push(oi);
    }
    
    let T: f64 = kani::any();
    kani::assume(T >= 0.0);
    
    let (x, cert) = project_weighted_l1(&v, &omega, T);
    
    // Certificate should indicate feasibility
    assert!(cert.feasible);
    
    // Mass should not exceed budget (with tolerance)
    assert!(cert.mass <= T + 1e-6);
}

#[kani::proof]
fn check_projection_preserves_sign() {
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 10);
    
    let mut v = Vec::with_capacity(n);
    let mut omega = Vec::with_capacity(n);
    
    for _ in 0..n {
        let vi: f64 = kani::any();
        let oi: f64 = kani::any();
        kani::assume(oi > 0.0);
        v.push(vi);
        omega.push(oi);
    }
    
    let T: f64 = kani::any();
    kani::assume(T >= 0.0);
    
    let (x, _) = project_weighted_l1(&v, &omega, T);
    
    // Projection should preserve signs
    for i in 0..n {
        if v[i] > 0.0 {
            assert!(x[i] >= 0.0);
        } else if v[i] < 0.0 {
            assert!(x[i] <= 0.0);
        } else {
            assert!(x[i].abs() < 1e-6);
        }
    }
}

#[kani::proof]
fn check_projection_no_larger_than_input() {
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 10);
    
    let mut v = Vec::with_capacity(n);
    let mut omega = Vec::with_capacity(n);
    
    for _ in 0..n {
        let vi: f64 = kani::any();
        let oi: f64 = kani::any();
        kani::assume(oi > 0.0);
        v.push(vi);
        omega.push(oi);
    }
    
    let T: f64 = kani::any();
    kani::assume(T >= 0.0);
    
    let (x, _) = project_weighted_l1(&v, &omega, T);
    
    // Projection should not increase the value of any component
    for i in 0..n {
        assert!(x[i].abs() <= v[i].abs() + 1e-6);
    }
}
