//! SpiralCore v14.1 Kani verification harness.
//!
//! Run with: cargo kani --tests --unwind 5

#[cfg(kani)]
mod verification {
    use super::*;
    use crate::constants::*;
    use crate::cantor::{pair, pair_nonnegative, pair_inj_left, pair_inj_right};
    use crate::zigzag::{encode, decode, roundtrip_ok};
    use crate::attractor::{xi_attractor, amplitude_bounded};
    use crate::alignment::{pas_s, pas_s_bounded, can_seal, drift_within_threshold};
    use crate::phase_lift::{rotate90, rotate90_cycle_ok, norm_preserved, polarity_inversion};
    use crate::fbs::FBSAtomicProfile;
    use crate::godel::godel_metric;
    use crate::boot::{valid_transition, BootStatus};

    // =========================================================================
    // Core constants verification
    // =========================================================================

    #[kani::proof]
    fn verify_l0_formula() {
        assert!(L0 == 3 * TAU + 2, "L0 must equal 3*tau + 2");
    }

    #[kani::proof]
    fn verify_h0_formula() {
        assert!(H0 == 6 * TAU + 3, "H0 must equal 6*tau + 3");
    }

    #[kani::proof]
    fn verify_q0_formula() {
        assert!(Q0 == 6 * TAU + 5, "Q0 must equal 6*tau + 5");
    }

    #[kani::proof]
    fn verify_q0_h0_relation() {
        assert!(Q0 == H0 + 2, "Q0 must equal H0 + 2");
    }

    #[kani::proof]
    fn verify_dim_positive() {
        assert!(DIM >= 1, "DIM must be positive");
    }

    #[kani::proof]
    fn verify_tau_at_least_2() {
        assert!(TAU >= 2, "tau must be >= 2");
    }

    #[kani::proof]
    fn verify_g_bounds() {
        assert!(G >= 1 && G < TAU, "g must satisfy 1 <= g < tau");
    }

    #[kani::proof]
    fn verify_theta_emit_in_unit_interval() {
        assert!(0.0 <= THETA_EMIT && THETA_EMIT <= 1.0, "theta_emit must be in [0,1]");
    }

    #[kani::proof]
    fn verify_epsilon_drift_in_unit_interval() {
        assert!(0.0 <= EPSILON_DRIFT && EPSILON_DRIFT <= 1.0, "epsilon_drift must be in [0,1]");
    }

    #[kani::proof]
    fn verify_xi_amplitude_nonnegative() {
        assert!(XI_AMPLITUDE >= 0.0, "xi_amplitude must be nonnegative");
    }

    // =========================================================================
    // Cantor pairing verification
    // =========================================================================

    #[kani::proof]
    #[kani::unwind(11)]
    fn verify_cantor_pair_nonnegative() {
        let a: usize = kani::any();
        let b: usize = kani::any();
        kani::assume(a <= 100);
        kani::assume(b <= 100);
        assert!(pair(a, b) >= 0, "Cantor pair must be nonnegative");
    }

    #[kani::proof]
    #[kani::unwind(11)]
    fn verify_cantor_pair_injective_left() {
        let a1: usize = kani::any();
        let a2: usize = kani::any();
        let b: usize = kani::any();
        kani::assume(a1 <= 50);
        kani::assume(a2 <= 50);
        kani::assume(b <= 50);
        if pair(a1, b) == pair(a2, b) {
            assert!(a1 == a2, "Cantor pair must be injective in first argument");
        }
    }

    #[kani::proof]
    #[kani::unwind(11)]
    fn verify_cantor_pair_injective_right() {
        let a: usize = kani::any();
        let b1: usize = kani::any();
        let b2: usize = kani::any();
        kani::assume(a <= 50);
        kani::assume(b1 <= 50);
        kani::assume(b2 <= 50);
        if pair(a, b1) == pair(a, b2) {
            assert!(b1 == b2, "Cantor pair must be injective in second argument");
        }
    }

    // =========================================================================
    // Zigzag encoding verification
    // =========================================================================

    #[kani::proof]
    #[kani::unwind(11)]
    fn verify_zigzag_roundtrip() {
        let n: i64 = kani::any();
        kani::assume(n >= -100 && n <= 100);
        assert!(roundtrip_ok(n), "Zigzag round-trip must hold");
    }

    // =========================================================================
    // Attractor verification
    // =========================================================================

    #[kani::proof]
    #[kani::unwind(11)]
    fn verify_attractor_amplitude_bounded() {
        let i: usize = kani::any();
        let phi0: f64 = kani::any();
        kani::assume(i < DIM);
        kani::assume(phi0 >= 0.0 && phi0 <= 6.28);
        assert!(amplitude_bounded(i, phi0), "Attractor amplitude must be bounded");
    }

    // =========================================================================
    // Phase alignment verification
    // =========================================================================

    #[kani::proof]
    #[kani::unwind(11)]
    fn verify_pas_s_bounded() {
        // Create a fixed set of phases for symbolic check
        let thetas: [f64; 4] = [0.0, 0.1, 0.05, -0.1];
        let pas = pas_s(&thetas);
        assert!(pas_s_bounded(pas), "PAS_s must be bounded in [0,1]");
    }

    #[kani::proof]
    fn verify_can_seal_high_pas() {
        let pas = Some(0.95);
        assert!(can_seal(pas), "High PAS should seal");
    }

    #[kani::proof]
    fn verify_cannot_seal_low_pas() {
        let pas = Some(0.5);
        assert!(!can_seal(pas), "Low PAS should not seal");
    }

    // =========================================================================
    // Orthogonal phase-lift verification
    // =========================================================================

    #[kani::proof]
    fn verify_rotate90_norm_preservation() {
        let x: f64 = kani::any();
        let y: f64 = kani::any();
        kani::assume(x >= -10.0 && x <= 10.0);
        kani::assume(y >= -10.0 && y <= 10.0);
        assert!(norm_preserved(x, y), "Rotate90 must preserve Euclidean norm");
    }

    #[kani::proof]
    fn verify_rotate90_cycle() {
        let x: f64 = kani::any();
        let y: f64 = kani::any();
        kani::assume(x >= -10.0 && x <= 10.0);
        kani::assume(y >= -10.0 && y <= 10.0);
        assert!(rotate90_cycle_ok(x, y), "Four 90-degree rotations must return to original");
    }

    #[kani::proof]
    fn verify_polarity_involution() {
        let s: bool = kani::any();
        assert!(polarity_inversion(polarity_inversion(s)) == s, "Polarity inversion is an involution");
    }

    // =========================================================================
    // FBS atomic profile verification
    // =========================================================================

    #[kani::proof]
    fn verify_fbs_default_l0() {
        let prof = FBSAtomicProfile::default_mode_a();
        assert!(prof.L0_ == L0, "Default L0 must match constant");
    }

    #[kani::proof]
    fn verify_fbs_default_h0() {
        let prof = FBSAtomicProfile::default_mode_a();
        assert!(prof.H0_ == H0, "Default H0 must match constant");
    }

    #[kani::proof]
    fn verify_fbs_default_q0() {
        let prof = FBSAtomicProfile::default_mode_a();
        assert!(prof.Q0_ == Q0, "Default Q0 must match constant");
    }

    // =========================================================================
    // Gödel metric verification
    // =========================================================================

    #[kani::proof]
    #[kani::unwind(11)]
    fn verify_godel_bounded() {
        let x_len: usize = kani::any();
        kani::assume(x_len >= 1 && x_len <= 4);
        let mut x_raw_next = vec![0.0f64; x_len];
        let mut f_a = vec![0.0f64; x_len];
        for i in 0..x_len {
            x_raw_next[i] = (i as f64) + 1.0;
            f_a[i] = (i as f64) + 0.5;
        }
        assert!(godel::godel_bounded(&x_raw_next, &f_a, 1e-9), "Gödel metric must be bounded");
    }

    // =========================================================================
    // Boot state machine verification
    // =========================================================================

    #[kani::proof]
    fn verify_boot_transitions() {
        assert!(valid_transition(BootStatus::Uninitialized, BootStatus::Validating));
        assert!(valid_transition(BootStatus::Validating, BootStatus::Allocating));
        assert!(valid_transition(BootStatus::Allocating, BootStatus::Sealed));
        assert!(valid_transition(BootStatus::Sealed, BootStatus::HandedOff));
        assert!(valid_transition(BootStatus::Validating, BootStatus::BootAbort));
        assert!(valid_transition(BootStatus::Allocating, BootStatus::BootAbort));
    }

    #[kani::proof]
    fn verify_invalid_boot_transitions() {
        let from = BootStatus::Uninitialized;
        let to = BootStatus::Sealed;
        assert!(!valid_transition(from, to), "Cannot skip Validating/Allocating");
    }
}
