use echo_braid::*;

fn make_test_braid() -> EchoBraidState {
    let s1 = Strand::new(2, 1, 0, 80, 90, 0);
    let s2 = Strand::new(3, 2, 120, 70, 85, 1);
    let s3 = Strand::new(5, 3, 240, 60, 75, 2);
    EchoBraidState::new(0, vec![s1, s2, s3], 60, 85)
}

#[test]
fn test_distinct_primes_and_energy() {
    let st = make_test_braid();
    assert!(st.has_distinct_primes());
    assert_eq!(st.current_prime_sequence(), vec![2, 3, 5]);
    assert!(st.total_energy() > 0);
}

#[test]
fn test_floer_step_advances_time_and_bounds() {
    let st0 = make_test_braid();
    let st1 = floer_step(&st0);
    assert_eq!(st1.time, 1);
    assert!(st1.spectral_coherence <= 100);
    for s in &st1.strands {
        assert!(s.tint.intensity <= 100);
        assert!(s.eigen.amplitude <= 100);
    }
}

#[test]
fn test_braid_crossing_moves() {
    let st0 = make_test_braid();
    let st1 = apply_braid_move(&st0, BraidMove::CrossPos(0));
    assert_eq!(st1.current_prime_sequence(), vec![3, 2, 5]);

    // Inverse move returns to original order
    let st2 = apply_braid_move(&st1, BraidMove::CrossNeg(0));
    assert_eq!(st2.current_prime_sequence(), vec![2, 3, 5]);
}

#[test]
fn test_artin_far_commutativity() {
    let s1 = Strand::new(2, 1, 0, 80, 90, 0);
    let s2 = Strand::new(3, 2, 120, 70, 85, 1);
    let s3 = Strand::new(5, 3, 240, 60, 75, 2);
    let s4 = Strand::new(7, 4, 300, 50, 70, 3);
    let st = EchoBraidState::new(0, vec![s1, s2, s3, s4], 60, 80);

    let word1 = [BraidMove::CrossPos(0), BraidMove::CrossPos(2)];
    let word2 = [BraidMove::CrossPos(2), BraidMove::CrossPos(0)];

    let st_res1 = apply_braid_word(&st, &word1);
    let st_res2 = apply_braid_word(&st, &word2);

    assert_eq!(st_res1.current_prime_sequence(), st_res2.current_prime_sequence());
    assert_eq!(st_res1.current_prime_sequence(), vec![3, 2, 7, 5]);
}

#[test]
fn test_picard_iteration_convergence() {
    let st0 = make_test_braid();
    let st_picard = iterate_picard(&st0, 15);
    assert_eq!(st_picard.strands.len(), 3);
    assert!(st_picard.total_energy() > 0);
}

#[test]
fn test_error_prediction_and_csl_validation() {
    let st0 = make_test_braid();
    let st1 = floer_step(&st0);

    let pred0 = ErrorPredictionState {
        alpha_weights: vec![50],
        beta_weights: vec![30],
        delta_prev: 10,
        delta_current: 10,
    };
    let vels = compute_state_velocity(&st0, &st1);
    let pred1 = evaluate_error_prediction(&pred0, &vels);

    let config = CSLConstraintConfig::default();
    let csl_res = validate_csl_constraints(&config, &st0, &st1, &pred1);
    assert!(csl_res.is_lawful);
    assert_eq!(csl_res.witness_digest, "CSL_WITNESS_VERIFIED_STABLE");

    let witness = generate_unified_witness(&st1, &csl_res);
    assert!(witness.is_stable);
    assert!(!witness.signature_hash.is_empty());
}

#[test]
fn test_governance_gateway_decision() {
    let st0 = make_test_braid();
    let st1 = floer_step(&st0);

    let pred = ErrorPredictionState {
        alpha_weights: vec![50],
        beta_weights: vec![30],
        delta_prev: 5,
        delta_current: 5,
    };

    let gateway = GovernanceGateway::new(CSLConstraintConfig::default());
    let decision = gateway.evaluate_transition(&st0, &st1, &pred);

    match decision {
        GovernanceDecision::Lawful { witness, validation } => {
            assert!(witness.is_stable);
            assert!(validation.is_lawful);
            assert!(!witness.signature_hash.is_empty());
        }
        GovernanceDecision::FailClosedHalt { .. } => {
            panic!("Expected lawful transition, got halt");
        }
    }
}

