use neuroplasticity::echo_braid::EchoBraidCoordinator;
use neuroplasticity::eeg_interface::EegInterface;
use neuroplasticity::types::{CognitiveState, PrimeComponent};

#[test]
fn test_echo_braid_phase_coherence() {
    let coordinator = EchoBraidCoordinator::new();

    // In-phase identity components -> Coherence R ≈ 1.0
    let coherent_state = CognitiveState::new(
        vec![
            PrimeComponent::new(2, 1.0, 0.1),
            PrimeComponent::new(3, 1.0, 0.1),
            PrimeComponent::new(5, 1.0, 0.1),
        ],
        0,
    );
    let r_coherent = coordinator.compute_identity_coherence(&coherent_state);
    assert!((r_coherent - 1.0).abs() < 1e-4);
    assert!(coordinator.is_identity_stable(&coherent_state));

    // Opposing phase components -> Low Coherence
    let incoherent_state = CognitiveState::new(
        vec![
            PrimeComponent::new(2, 1.0, 0.0),
            PrimeComponent::new(3, 1.0, std::f64::consts::PI),
        ],
        0,
    );
    let r_incoherent = coordinator.compute_identity_coherence(&incoherent_state);
    assert!(r_incoherent < 0.2);
}

#[test]
fn test_eeg_subjective_readiness() {
    let calm_eeg = EegInterface::simulate_eeg_bands("calm_focus");
    let stress_eeg = EegInterface::simulate_eeg_bands("stress_overload");

    let calm_readiness = EegInterface::compute_subjective_readiness(&calm_eeg);
    let stress_readiness = EegInterface::compute_subjective_readiness(&stress_eeg);

    assert!(calm_readiness > stress_readiness, "Calm focus must yield higher readiness than stress");
    assert!(calm_readiness >= 0.1 && calm_readiness <= 1.0);
}
