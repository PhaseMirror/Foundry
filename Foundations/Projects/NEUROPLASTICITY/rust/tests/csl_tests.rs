use neuroplasticity::csl::CslAuditor;
use neuroplasticity::types::{CognitiveState, NeuroConfig, PrimeComponent};

#[test]
fn test_csl_golden_ratio_bound() {
    let bound = CslAuditor::golden_ratio_entropy_bound();
    // ln((1 + sqrt(5))/2) ≈ 0.4812118
    assert!((bound - 0.4812118).abs() < 1e-5);
}

#[test]
fn test_csl_audit_and_homeostatic_damping() {
    let config = NeuroConfig::default();
    let auditor = CslAuditor::new(config);

    let state_a = CognitiveState::new(
        vec![
            PrimeComponent::new(2, 1.0, 0.0),
            PrimeComponent::new(3, 1.0, 0.0),
        ],
        0,
    );
    // Huge perturbation that changes entropy drastically
    let state_runaway = CognitiveState::new(
        vec![
            PrimeComponent::new(2, 100.0, 0.0),
            PrimeComponent::new(3, 0.001, 0.0),
        ],
        1,
    );

    let (satisfied, delta_s) = auditor.audit_transition(&state_a, &state_runaway);
    assert!(!satisfied, "Drastic entropy shift must breach CSL");
    assert!(delta_s > 0.4812);

    let damped = auditor.enforce_homeostasis(&state_runaway);
    assert!(damped.total_power() < state_runaway.total_power(), "Damping must reduce runaway power");
}
