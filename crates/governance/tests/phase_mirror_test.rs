use governance_core_rs::phase_mirror::*;

#[test]
fn test_semantic_parom_evolution() {
    let parom = SemanticParom::new(vec![2, 3, 5, 7, 11, 13]);
    let (next_rho, composite) = parom.evolve(0.5);
    
    assert!(next_rho >= 0.0);
    assert!(composite > 0);
}

#[test]
fn test_evaluate_state_transition_empty() {
    let report = evaluate_state_transition("", "{}", "none");
    assert!(report.execute); // empty input adds 0.3, which is < 1.0
    assert!(report.tensions.iter().any(|s| s.signal_id == "empty_transition_input"));
}

#[test]
fn test_evaluate_rollback_trigger() {
    let report = evaluate_state_transition("some input", "{}", "emergency_rollback");
    assert!(report.rho >= 0.5);
    assert!(report.tensions.iter().any(|s| s.signal_id == "rollback_trigger_active"));
}
