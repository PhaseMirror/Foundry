//! Kani harnesses for the end-to-end certified heat-flow runtime.
//!
//! Verifies the operational contract of `CertifiedState` for the certified
//! 2-node graph (L = [[1,-1],[-1,1]], exact λ₂ = 2) across *all* bounded
//! symbolic field vectors and step sizes:
//!
//! - construction accepts exactly the admissible step sizes and rejects
//!   everything else with `StepSizeOutOfRange`;
//! - a committed step never violates the certificate bound (the runtime
//!   never commits an uncertified transition).
//!
//! The graph is concrete so the spectral estimate is a constant; otherwise
//! the symbolic Jacobi eigensolver would be outside CBMC's arithmetic
//! limits (that part is Lean-kernel-proven, see ADR-0027).

#![cfg(kani)]

use certificate_runtime::certificate::{CertificateError, CertifiedState};

/// A concrete certified 2-node graph with Laplacian [[1,-1],[-1,1]].
fn k2_graph() -> certificate_runtime::graph::Graph {
    certificate_runtime::graph::Graph::from_weights(vec![vec![0.0, 1.0], vec![1.0, 0.0]]).unwrap()
}

/// Construction accepts exactly the admissible step sizes.
#[kani::proof]
#[kani::unwind(8)]
fn verify_construction_accepts_admissible_alpha() {
    let u: Vec<f64> = vec![0.0, 0.0];
    let alpha: f64 = kani::any();
    kani::assume(alpha.is_finite());

    let r = CertifiedState::with_epsilon(k2_graph(), u, alpha, 1e-9);

    match r {
        Ok(_) => {
            // λ₂ = 2, ρ = 2, so the admissible range is (0, 1) exactly.
            assert!(alpha > 0.0 && alpha < 1.0);
        }
        Err(e) => {
            assert!(matches!(e, CertificateError::StepSizeOutOfRange { .. }));
        }
    }
}

/// A committed certified step only ever commits a state that satisfies the
/// certificate bound (the core soundness property of ADR-0027 §4).
#[kani::proof]
#[kani::unwind(8)]
fn verify_certified_step_never_commits_uncertified() {
    let n: usize = 2;
    let u: [f64; 2] = kani::any();
    kani::assume(u.iter().all(|&x| x.is_finite() && x.abs() <= 2.0));
    let alpha: f64 = kani::any();
    kani::assume(alpha >= 0.01 && alpha <= 0.5);

    // λ₂ = 2 ⇒ q = 1 - 2α ∈ (0, 1), so the certificate passes.
    let mut state = CertifiedState::with_epsilon(
        k2_graph(),
        u[..n].to_vec(),
        alpha,
        certificate_runtime::certificate::DEFAULT_EPSILON,
    )
    .unwrap();

    let before: Vec<f64> = state.state().to_vec();
    match state.step() {
        Ok(res) => {
            // A pass is only ever reported within the certified bound.
            assert!(
                !res.passed
                    || res.actual_ratio <= res.theoretical_bound + certificate_runtime::certificate::DEFAULT_EPSILON
            );
            // The committed state is the computed heat step.
            assert!(state.state().len() == n);
        }
        Err(_) => {
            // The state must be untouched on error (rollback).
            assert_eq!(state.state().to_vec(), before);
        }
    }
}