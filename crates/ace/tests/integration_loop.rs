//! Phase 1 integration test – end‑to‑end loop for ACEGuardian.

use num_rational::Ratio;
use ace::guardian::ACEGuardian;

#[test]
fn test_aceguardian_success_and_failure() {
    // γ = 0.9 (contractivity bound)
    let gamma = Ratio::new_raw(9, 10);
    let guardian = ACEGuardian::new(gamma);

    // Valid transition: φ = 0.5 < γ
    let phi_valid = Ratio::new_raw(1, 2);
    let ok = guardian.process_transition(phi_valid);
    assert!(ok.is_ok(), Valid
