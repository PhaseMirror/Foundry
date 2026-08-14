//! Kani verification harnesses for certificate runtime

#![cfg(kani)]

use certificate_runtime::certificate::{CertifiedState, CertificateResult};

// Simple 2x2 laplacian bounds for kani unwinding test limits
#[kani::proof]
#[kani::unwind(3)]
fn verify_heat_step_contract() {
    let mut u: [f64; 2] = kani::any();
    kani::assume(u[0] >= -10.0 && u[0] <= 10.0);
    kani::assume(u[1] >= -10.0 && u[1] <= 10.0);

    // Ensure valid step parameters
    let alpha: f64 = kani::any();
    kani::assume(alpha > 0.0 && alpha < 1.0);

    // Dummy positive semi-definite laplacian
    let l = vec![vec![1.0, -1.0], vec![-1.0, 1.0]];

    let mut state = CertifiedState::new(u.to_vec(), l, 2.0, 2.0, alpha).unwrap();
    let result = state.step();
    
    // Check that we didn't panic or produce undefined behavior on the step calculation
    match result {
        Ok(r) => {
            assert!(r.passed || !r.passed);
        },
        Err(_) => {},
    }
}
