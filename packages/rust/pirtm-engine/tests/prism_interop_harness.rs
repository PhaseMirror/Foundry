//! ADR-0066 §"Rust/Kani Integration Harness" — `prism_interop_harness.rs`.
//!
//! The ADR's canonical interop scenario: a semantically-valid PrismPM model
//! (directory `Verify/Langlands/Add/ow_tm_smoothing.tm.lex.tex` with zero-sorry
//! Lean 4 proofs) is manufactured into the PIRTM manifold. The factory's
//! semantic gate passes — but the *adversarial* gain matrix
//! `[[1, 0.5], [0.5, 1]]` pushes `ρ(Ψ) = 1.5 ≥ 1 − ε`, so the Arithmetic
//! Control Engine must veto, regardless of semantics.
//!
//! Dual mode: under `cfg(kani)` these become `#[kani::proof]` harnesses run by
//! `cargo kani`; under `cargo test` the same scenarios execute as ordinary
//! Rust tests so the invariant is checked in both toolchains.

use pirtm_engine::ace::{
    CONTRACTIVITY_EPSILON, SigGovKill, evaluate_spectral_radius, verify_transition,
};
use pirtm_engine::tensor::GainMatrix;

/// The ADR's adversarial injection: `psi.set_weights(1.0, 0.5, 0.5, 1.0)`.
fn adversarial_injection() -> GainMatrix {
    let mut psi = GainMatrix::new_2x2();
    psi.set_weights(1.0, 0.5, 0.5, 1.0);
    psi
}

/// A clearly contractive control matrix: `ρ = 0.5`.
fn flutter_matrix() -> GainMatrix {
    let mut psi = GainMatrix::new_2x2();
    psi.set_weights(0.25, 0.0, 0.0, 0.5);
    psi
}

#[cfg(kani)]
mod verification {
    use super::*;

    /// The veto must fire for the adversarial injection even though the
    /// semantic proofs were valid (the kill is a *control-plane* decision).
    #[kani::proof]
    #[kani::unwind(8)]
    fn adversarial_gain_is_vetoed_despite_valid_semantics() {
        let psi = adversarial_injection();
        let rho = evaluate_spectral_radius(&psi);
        kani::assert(
            rho >= 1.0 - CONTRACTIVITY_EPSILON,
            "adversarial injection breaches the contractivity bound",
        );
        let result = verify_transition(&psi, true);
        kani::assert(
            result == Err(SigGovKill::ExpansiveState),
            "ACE kills the expansive transition with SIG_GOV_KILL",
        );
    }

    /// The orthogonal property: an invalid semantic proof is rejected even
    /// when the gain matrix is trivially contractive.
    #[kani::proof]
    #[kani::unwind(8)]
    fn invalid_semantics_are_rejected() {
        let psi = flutter_matrix();
        match verify_transition(&psi, false) {
            Ok(()) => kani::assert(false, "semantic gate must reject invalid proofs"),
            Err(kill) => kani::assert(
                kill == SigGovKill::SemanticProofInvalid,
                "must fail with the semantic discriminant",
            ),
        }
    }
}

#[cfg(not(kani))]
mod runtime {
    use super::*;

    #[test]
    fn adversarial_gain_is_vetoed_despite_valid_semantics() {
        let psi = adversarial_injection();
        let rho = evaluate_spectral_radius(&psi);
        assert!(rho >= 1.0 - CONTRACTIVITY_EPSILON);
        assert_eq!(verify_transition(&psi, true), Err(SigGovKill::ExpansiveState));
    }

    #[test]
    fn contractive_control_matrix_is_admitted() {
        assert_eq!(verify_transition(&flutter_matrix(), true), Ok(()));
    }

    #[test]
    fn invalid_semantics_are_rejected() {
        assert_eq!(
            verify_transition(&flutter_matrix(), false),
            Err(SigGovKill::SemanticProofInvalid)
        );
    }
}