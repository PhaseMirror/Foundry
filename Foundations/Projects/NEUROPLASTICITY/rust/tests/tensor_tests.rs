use neuroplasticity::tensor::PirtmEngine;
use neuroplasticity::types::{CognitiveState, PrimeComponent};

#[test]
fn test_prime_orthogonality_and_inner_product() {
    let state_a = CognitiveState::new(
        vec![
            PrimeComponent::new(2, 1.0, 0.0),
            PrimeComponent::new(3, 0.5, 0.0),
        ],
        0,
    );
    let state_b = CognitiveState::new(
        vec![
            PrimeComponent::new(5, 1.0, 0.0),
            PrimeComponent::new(7, 0.5, 0.0),
        ],
        0,
    );

    // Completely disjoint prime channels have zero inner product
    let (real, imag) = PirtmEngine::inner_product(&state_a, &state_b);
    assert_eq!(real, 0.0);
    assert_eq!(imag, 0.0);

    // Self inner product equals total power
    let (self_real, self_imag) = PirtmEngine::inner_product(&state_a, &state_a);
    assert!((self_real - state_a.total_power()).abs() < 1e-6);
    assert!(self_imag.abs() < 1e-6);
}

#[test]
fn test_spectral_entropy_non_negative() {
    let state = PirtmEngine::initialize_default_state(5);
    let entropy = PirtmEngine::spectral_entropy(&state);
    assert!(entropy >= 0.0, "Entropy must be non-negative");
    assert!(entropy.is_finite());
}
