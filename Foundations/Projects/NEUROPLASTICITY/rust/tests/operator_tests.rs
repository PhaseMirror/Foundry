use neuroplasticity::operator::RecursiveOperator;
use neuroplasticity::types::{CognitiveState, NeuroConfig, PrimeComponent};

#[test]
fn test_recursive_operator_growth_and_decay() {
    let config = NeuroConfig {
        learning_rate: 0.1,
        synaptic_decay: 0.05,
        ..Default::default()
    };
    let operator = RecursiveOperator::new(config);
    let initial = CognitiveState::new(vec![PrimeComponent::new(2, 1.0, 0.0)], 0);

    // Step with positive stimulus
    let next = operator.step(&initial, &[1.0], 1.0);
    assert_eq!(next.timestamp, 1);
    // Expected: 1.0 * (1 - 0.05) + 0.1 * 1.0 = 0.95 + 0.1 = 1.05
    assert!((next.components[0].amplitude - 1.05).abs() < 1e-6);

    // Step with zero stimulus -> decay
    let decayed = operator.step(&next, &[0.0], 1.0);
    assert!(decayed.components[0].amplitude < next.components[0].amplitude);
}
