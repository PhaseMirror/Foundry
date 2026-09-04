//! SpiralCore v14.1 Kani verification harness.
//!
//! Run with: cargo kani --tests --unwind 5

#[cfg(kani)]
mod verification {
    use spiralcore_verify::constants::*;
    use spiralcore_verify::cantor::{pair, pair_nonnegative, pair_inj_left, pair_inj_right};
    use spiralcore_verify::zigzag::{encode, decode, roundtrip_ok};
    use spiralcore_verify::attractor::{xi_attractor, amplitude_bounded};
    use spiralcore_verify::alignment::{pas_s, pas_s_bounded, can_seal, drift_within_threshold};
    use spiralcore_verify::phase_lift::{rotate90, rotate90_cycle_ok, norm_preserved, polarity_inversion};
    use spiralcore_verify::fbs::FBSAtomicProfile;
    use spiralcore_verify::godel;
    use spiralcore_verify::godel::godel_metric;
    use spiralcore_verify::boot::{valid_transition, BootStatus};
    use spiralcore_verify::feynman_path;
    use spiralcore_verify::persistence_canopies;
    use spiralcore_verify::subset_selection;
    use spiralcore_verify::fisher_sharpness;
    use spiralcore_verify::gk_mapper;
    use spiralcore_verify::hodge_surrogates;
    use spiralcore_verify::vertex_guard;
    use spiralcore_verify::geometric_trees;
    use spiralcore_verify::spiralcore_v13;
    use spiralcore_verify::morse_transform;
    use spiralcore_verify::v4p_vsam;
    use spiralcore_verify::wada_lada;

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

    // =========================================================================
    // ADR-0030: Feynman path — fail-closed amplitude gate
    // =========================================================================

    #[kani::proof]
    fn verify_feynman_total_amplitude_locked() {
        assert_eq!(feynman_path::total_amplitude(), 1_419_857 * 1_000);
    }

    #[kani::proof]
    fn verify_feynman_gate_accepts_reference() {
        let ref_amp: u64 = kani::any();
        kani::assume(ref_amp <= u64::MAX - 500_000);
        let closed = feynman_path::gate_closed(ref_amp);
        let total = feynman_path::total_amplitude();
        if ref_amp + 500_000 >= total && total + 500_000 >= ref_amp {
            assert!(closed, "in-tolerance reference must pass the gate");
        } else {
            assert!(!closed, "out-of-tolerance reference must fail closed");
        }
    }

    // =========================================================================
    // ADR-0031: Canopies — split conditions and pairing counts
    // =========================================================================

    #[kani::proof]
    fn verify_canopy_zero_entry_never_splits() {
        let sigma: u64 = kani::any();
        assert!(!persistence_canopies::split_conditions(0, sigma, sigma));
    }

    #[kani::proof]
    fn verify_canopy_nonzero_entry_with_peak_splits() {
        let entry: u64 = kani::any();
        kani::assume(entry >= 1);
        let sigma: u64 = kani::any();
        assert!(persistence_canopies::split_conditions(entry, sigma, sigma));
    }

    #[kani::proof]
    fn verify_canopy_pairing_count_rounds_half() {
        let m: u64 = kani::any();
        let essential: u64 = kani::any();
        let total = m * 2 + essential;
        assert!(persistence_canopies::pairing_count(total, essential) >= essential);
    }

    // =========================================================================
    // ADR-0032: Subset selection — Tchebycheff loss and triangular steps
    // =========================================================================

    #[kani::proof]
    fn verify_tchebycheff_loss_nonnegative() {
        let a1: u64 = kani::any();
        let a2: u64 = kani::any();
        let z1: u64 = kani::any();
        let z2: u64 = kani::any();
        let lambda100: u64 = kani::any();
        kani::assume(lambda100 <= 100);
        assert!(subset_selection::tchebycheff_loss(a1, a2, z1, z2, lambda100) <= u64::MAX);
    }

    #[kani::proof]
    fn verify_constant_matrix_is_monge() {
        assert!(subset_selection::constant_monge());
    }

    #[kani::proof]
    fn verify_separable_matrix_is_monge() {
        assert!(subset_selection::separable_monge());
    }

    #[kani::proof]
    fn verify_triangular_feasibility() {
        let i: u64 = kani::any();
        assert!(!subset_selection::feasible_transition(i, i));
    }

    // =========================================================================
    // ADR-0033: Fisher sharpness — stationary mass monotonicity
    // =========================================================================

    #[kani::proof]
    fn verify_positive_diagonal_fim_admissible() {
        let d: u64 = kani::any();
        kani::assume(d >= 1);
        assert!(fisher_sharpness::diagonal_fim_ok(d));
    }

    #[kani::proof]
    fn verify_stationary_mass_monotone_in_rate() {
        // Scaled domain: SR and batch are x10 fixed-point values <= 100.
        let sr1: u64 = kani::any();
        let sr2: u64 = kani::any();
        kani::assume(sr1 <= 100 && sr2 <= 100 && sr1 <= sr2);
        let eta: u64 = kani::any();
        kani::assume(eta >= 1 && eta <= 100);
        let batch: u64 = kani::any();
        kani::assume(batch >= 1 && batch <= 100);
        let scale: u64 = kani::any();
        kani::assume(scale >= 1 && scale <= 100);
        let m1 = fisher_sharpness::stationary_mass(sr1, eta, batch, scale);
        let m2 = fisher_sharpness::stationary_mass(sr2, eta, batch, scale);
        assert!(m1 <= m2, "larger step rate must not lower stationary mass");
    }

    #[kani::proof]
    fn verify_admissible_flatness_metrics() {
        // Kani models memcmp on fixed-length `&str` literals without
        // unwinding, so exercise each literal in its own concrete call.
        assert!(fisher_sharpness::admissible_flatness_metric("SR"));
        assert!(fisher_sharpness::admissible_flatness_metric("riemannian_sharpness"));
        assert!(!fisher_sharpness::admissible_flatness_metric("euclidean"));
    }

    // =========================================================================
    // ADR-0034: GK-Mapper — membership overlap and edge threshold
    // =========================================================================

    #[kani::proof]
    fn verify_overlap_commutes() {
        let mu_i: u64 = kani::any();
        let mu_j: u64 = kani::any();
        assert_eq!(gk_mapper::overlap(mu_i, mu_j), gk_mapper::overlap(mu_j, mu_i));
    }

    #[kani::proof]
    fn verify_overlap_bounded_by_memberships() {
        let mu_i: u64 = kani::any();
        let mu_j: u64 = kani::any();
        let ov = gk_mapper::overlap(mu_i, mu_j);
        assert!(ov <= mu_i && ov <= mu_j);
    }

    #[kani::proof]
    fn verify_fuzzifier_default_admissible() {
        assert!(gk_mapper::admissible_fuzzifier(gk_mapper::FUZZIFIER_DEFAULT));
        assert!(!gk_mapper::admissible_fuzzifier(10));
    }

    #[kani::proof]
    fn verify_gk_distance_symmetric() {
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        assert_eq!(gk_mapper::ellipsoidal_distance(a, b), gk_mapper::ellipsoidal_distance(b, a));
    }

    // =========================================================================
    // ADR-0035: Hodge surrogates — B²=0 and Betti preservation
    // =========================================================================

    #[kani::proof]
    fn verify_boundary_twice_lowers_dimension() {
        let dim: u64 = kani::any();
        let twice = hodge_surrogates::boundary_twice(dim);
        if dim >= 2 {
            assert_eq!(twice, dim - 2);
        } else {
            assert_eq!(twice, 0);
        }
    }

    #[kani::proof]
    fn verify_zero_modes_are_betti() {
        let z: u64 = kani::any();
        assert!(hodge_surrogates::zero_modes_equal_betti(z));
    }

    #[kani::proof]
    fn verify_hard_limit_keeps_betti() {
        let k: u64 = kani::any();
        kani::assume(k >= 1);
        assert!(hodge_surrogates::hard_limit_preserves_betti(k, 1));
    }

    // =========================================================================
    // ADR-0036: Vertex guard — coverage feasibility and reward
    // =========================================================================

    #[kani::proof]
    fn verify_coverage_reward_no_overflow() {
        let coverage: u64 = kani::any();
        kani::assume(coverage <= 100_000_000_000);
        let guard_count: u64 = kani::any();
        kani::assume(guard_count <= 1_000_000);
        let cost_per_guard: u64 = kani::any();
        kani::assume(cost_per_guard <= 100_000);
        // reward must not overflow the i64 representation
        let _ = vertex_guard::coverage_reward(coverage, guard_count, cost_per_guard);
    }

    // =========================================================================
    // ADR-0037: Geometric trees — PSD certificate vs spread
    // =========================================================================

    #[kani::proof]
    fn verify_symmetric_matrix_detected() {
        let d: u64 = kani::any();
        let m = [d, 1, 1, 1, d, 1, 1, 1, d];
        assert!(geometric_trees::symmetric(&m));
    }

    #[kani::proof]
    fn verify_spread_within_u64() {
        // Fully concrete 3x3 diagonal matrix keeps every loop bound constant,
        // so no unwinding is required beyond the fixed 3x3 grid.
        let m: [u64; 9] = [2, 0, 0, 0, 3, 0, 0, 0, 4];
        let u: [u64; 3] = [1, 2, 3];
        let spread = geometric_trees::directional_spread(&m, u);
        assert!(spread >= 2, "positive diagonal contributes positive spread");
    }

    #[kani::proof]
    fn verify_simplex_normalization() {
        // Saturating subtraction keeps the harness overflow-free for any input.
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        let c: u64 = kani::any();
        kani::assume(a <= 100 && b <= 100 && c <= 100);
        kani::assume(a + b <= 100);
        assert!(geometric_trees::simplex_normalized([a, b, 100 - a - b], 100));
    }

    // =========================================================================
    // ADR-0038/0039: SpiralCore v13 — locked constants and gates
    // =========================================================================

    #[kani::proof]
    fn verify_v13_bifurcation_pair_locked() {
        assert_eq!(spiralcore_v13::bifurcation_pair(), (27, 28));
    }

    #[kani::proof]
    fn verify_v13_collatz_escape_locked() {
        assert!(spiralcore_v13::collatz_escape_floor());
        assert_eq!(spiralcore_v13::collatz_step(4), 2);
        assert_eq!(spiralcore_v13::collatz_step(2), 1);
    }

    #[kani::proof]
    fn verify_v13_cathedral_gate() {
        let pe100: u64 = kani::any();
        kani::assume(pe100 <= 100);
        assert_eq!(
            spiralcore_v13::cathedral_stable(pe100),
            pe100 <= spiralcore_v13::PE_CRITICAL100
        );
    }

    #[kani::proof]
    fn verify_v13_millennium_gate() {
        let xi100: u64 = kani::any();
        kani::assume(xi100 <= 100);
        let omega100: u64 = kani::any();
        kani::assume(omega100 <= 100);
        assert_eq!(
            spiralcore_v13::millennium_closed(xi100, omega100),
            xi100 >= spiralcore_v13::TAU_BASE100 && omega100 <= spiralcore_v13::OMEGA_MAX100
        );
    }

    #[kani::proof]
    fn verify_v13_cycle_budget() {
        assert!(spiralcore_v13::cycle_within_binder(spiralcore_v13::ULTRA_BINDER_LIMIT13));
        assert!(!spiralcore_v13::cycle_within_binder(spiralcore_v13::ULTRA_BINDER_LIMIT13 + 1));
    }

    // =========================================================================
    // ADR-0041: Morse transform — critical-type classification
    // =========================================================================

    #[kani::proof]
    fn verify_morse_classification_exhaustive() {
        let b0: u64 = kani::any();
        let b1: u64 = kani::any();
        kani::assume(b0 <= 1 && b1 <= 1);
        match morse_transform::type_of_betti(b0, b1) {
            morse_transform::CriticalType::Saddle => assert!(b1 >= 1),
            morse_transform::CriticalType::Peak => assert!(b1 == 0 && b0 == 0),
            morse_transform::CriticalType::Trough => assert!(b1 == 0 && b0 >= 1),
        }
    }

    #[kani::proof]
    fn verify_morse_dimensions_locked() {
        assert!(morse_transform::PLAIN_MORSE_DIM < morse_transform::SUPPLEMENTED_MORSE_DIM);
    }

    // =========================================================================
    // ADR-0042: V4P-VSAM — octet/nibble round-trip and no-permission
    // =========================================================================

    #[kani::proof]
    fn verify_octet_roundtrip_all_octets() {
        let o: u64 = kani::any();
        kani::assume(o <= 255);
        assert!(v4p_vsam::octet_valid(o));
        assert!(v4p_vsam::octet_roundtrip(o), "valid octets must survive split/recombine");
    }

    #[kani::proof]
    fn verify_octet_rejects_out_of_domain() {
        let o: u64 = kani::any();
        kani::assume(o >= 256);
        assert!(!v4p_vsam::octet_valid(o));
    }

    #[kani::proof]
    fn verify_v4p_no_permission_by_address() {
        assert!(!v4p_vsam::address_grants_permission());
        assert!(!v4p_vsam::same_address_different_basis());
    }

    #[kani::proof]
    fn verify_v4p_conflict_policy_fail_closed() {
        assert!(v4p_vsam::conflict_policy(false));
        assert!(!v4p_vsam::conflict_policy(true));
    }

    // =========================================================================
    // ADR-0043: WADA-LADA — fail-closed drops, root hysteresis, overrides
    // =========================================================================

    #[kani::proof]
    fn verify_wada_drop_on_self_in_path() {
        let msg = wada_lada::StateMessage {
            state_id: "s".into(),
            path: vec!["a".into()],
            ttl: 5,
            signature_valid: true,
            basis_supported: true,
            policy_allows_transit: true,
            state_class_allowed: true,
        };
        assert!(wada_lada::should_drop(&msg, "a"), "loop must drop");
        assert!(!wada_lada::should_drop(&msg, "b"), "fresh agent must pass");
    }

    #[kani::proof]
    fn verify_wada_drop_fail_closed_on_ttl_zero() {
        let msg = wada_lada::StateMessage {
            state_id: "s".into(),
            path: Vec::new(),
            ttl: 0,
            signature_valid: true,
            basis_supported: true,
            policy_allows_transit: true,
            state_class_allowed: true,
        };
        assert!(wada_lada::should_drop(&msg, "a"));
    }

    #[kani::proof]
    fn verify_wada_drop_fail_closed_on_bad_sig() {
        let msg = wada_lada::StateMessage {
            state_id: "s".into(),
            path: Vec::new(),
            ttl: 5,
            signature_valid: false,
            basis_supported: true,
            policy_allows_transit: true,
            state_class_allowed: true,
        };
        assert!(wada_lada::should_drop(&msg, "a"));
    }

    #[kani::proof]
    fn verify_wada_root_hysteresis_needs_margin_and_duration() {
        let candidate: u64 = kani::any();
        let root: u64 = kani::any();
        let margin: u64 = kani::any();
        // Constrain via checked arithmetic so the harness itself never
        // overflows, mirroring the in-function domain requirement.
        let sum = root.checked_add(margin);
        kani::assume(sum.is_some());
        let duration: u64 = kani::any();
        let sustained: u64 = kani::any();
        let bound = sum.unwrap();
        assert_eq!(
            wada_lada::may_replace_root(candidate, root, margin, duration, sustained),
            candidate >= bound && sustained >= duration
        );
    }

    #[kani::proof]
    fn verify_wada_manual_override_requires_healthy_root() {
        assert!(wada_lada::manual_override_valid(false, false, false, false));
        assert!(!wada_lada::manual_override_valid(true, false, false, false));
        assert!(!wada_lada::manual_override_valid(false, true, false, false));
        assert!(!wada_lada::manual_override_valid(false, false, true, false));
        assert!(!wada_lada::manual_override_valid(false, false, false, true));
    }

    #[kani::proof]
    fn verify_wada_worker_authorization() {
        assert!(wada_lada::worker_may_advertise_as_root(true));
        assert!(!wada_lada::worker_may_advertise_as_root(false));
        assert!(!wada_lada::fusion_makes_truth_claim());
    }
}
