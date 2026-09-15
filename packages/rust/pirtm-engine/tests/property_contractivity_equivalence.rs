//! Property-based style invariant (per ADR-0066 test mandate): the float-level
//! transition gate and the fixed-point governance gate must agree on a bounded
//! lattice of concrete gain matrices.
//!
//! The lattice `{0, 1/16, 1/4, 1/2, 1}⁴` covers every qualitatively distinct
//! regime: contractive (`ρ` ≈ {0, 0.0625, …, 0.75}), the boundary (`ρ = 1.0`,
//! reject on both gates), and expansive (`ρ ∈ {1.25, 1.5}`).
//!
//! See [`pirtm_engine::manifest`] docs for the *exact* scaled (integer) gate
//! semantics; the two gates coincide on this lattice because no reachable
//! spectral radius lands inside the sub-ulp decision band
//! `[round((1−ε)·1e9) − 0.5, (1−ε))`.

use pirtm_engine::ace::{evaluate_spectral_radius, radius_scaled, verify_transition};
use pirtm_engine::manifest::default_spectral_limit;
use pirtm_engine::tensor::GainMatrix;

/// Candidate entries for each of the four weight slots.
const WEIGHTS: [f64; 5] = [0.0, 0.0625, 0.25, 0.5, 1.0];

/// Every 4-tuple of `WEIGHTS`; calls `f` once per matrix.
fn sweep(mut f: impl FnMut(&GainMatrix)) {
    for a in WEIGHTS {
        for b in WEIGHTS {
            for c in WEIGHTS {
                for d in WEIGHTS {
                    let mut psi = GainMatrix::new_2x2();
                    psi.set_weights(a, b, c, d);
                    f(&psi);
                }
            }
        }
    }
}

#[test]
fn float_gate_and_fixed_point_gate_always_agree_on_the_lattice() {
    let limit = default_spectral_limit();
    let mut checked = 0usize;
    sweep(|psi| {
        let rho = evaluate_spectral_radius(psi);
        let float_veto = verify_transition(psi, true).is_err();
        let scaled_veto = radius_scaled(psi) >= limit;
        assert_eq!(
            float_veto, scaled_veto,
            "gates disagree on psi={psi:?} with rho={rho}, scaled={}",
            radius_scaled(psi)
        );
        checked += 1;
    });
    assert_eq!(checked, WEIGHTS.len().pow(4));
}

#[test]
fn exact_adr_injection_is_caught_in_every_gate_layer() {
    let mut psi = GainMatrix::new_2x2();
    psi.set_weights(1.0, 0.5, 0.5, 1.0);
    assert_eq!(verify_transition(&psi, true).unwrap_err(), pirtm_engine::ace::SigGovKill::ExpansiveState);
    assert!(radius_scaled(&psi) >= default_spectral_limit());
    assert!(evaluate_spectral_radius(&psi) >= 1.0);
}

#[test]
fn identity_flux_is_rejected_at_the_boundary_on_both_gates() {
    let mut psi = GainMatrix::new_2x2();
    psi.set_weights(1.0, 0.0, 0.0, 1.0); // ρ = 1.0 ≥ 1−ε
    assert!(verify_transition(&psi, true).is_err());
    assert!(radius_scaled(&psi) >= default_spectral_limit());
}

#[test]
fn strictly_contractive_flux_is_admitted_on_both_gates() {
    let mut psi = GainMatrix::new_2x2();
    psi.set_weights(0.5, 0.25, 0.25, 0.5); // ρ = 0.75
    assert_eq!(verify_transition(&psi, true), Ok(()));
    assert!(radius_scaled(&psi) < default_spectral_limit());
}