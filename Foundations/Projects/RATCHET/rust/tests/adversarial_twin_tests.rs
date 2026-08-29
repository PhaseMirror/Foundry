use ratchet::adversarial_twin::{AdversarialError, AdversarialTwin, ModificationProposal, PreCommitGate};
use ratchet::controller::{ControllerConfig, ExternalController};
use ratchet::plant::ChaoticPlant;
use ratchet::snapshot_store::SnapshotStore;
use ratchet::types::{Mode, PlantState};

fn sample_plant_state() -> PlantState {
    let plant = ChaoticPlant::new();
    plant.state
}

#[test]
fn test_sign_inverted_twin_initialization() {
    let kernel_weights = vec![1.2, -0.5, 0.8, -2.1];
    let twin = AdversarialTwin::from_kernel(&kernel_weights, 1.5);

    assert_eq!(twin.inverted_weights, vec![-1.2, 0.5, -0.8, 2.1]);
    assert_eq!(twin.threshold, 1.03);
    assert_eq!(twin.n_steps, 100);
}

#[test]
fn test_adversarial_stress_test_nominal_pass() {
    let twin = AdversarialTwin::default_dim(2);
    let initial_state = sample_plant_state();

    // Very small, safe modification
    let proposal = ModificationProposal {
        delta_theta: vec![0.0001, 0.0001],
        delta_coordinates: 0,
        proposed_state: initial_state.clone(),
        null_space_residual: 0.001,
    };

    let result = twin.stress_test(&initial_state, &proposal);
    assert!(result.is_ok(), "Nominal modification must pass stress test");
}

#[test]
fn test_adversarial_stress_test_divergent_rejection() {
    let twin = AdversarialTwin::default_dim(2);
    let initial_state = sample_plant_state();

    // Large adversarial perturbation aligned with sign-inverted weights
    let proposal = ModificationProposal {
        delta_theta: vec![50.0, 50.0],
        delta_coordinates: 2,
        proposed_state: initial_state.clone(),
        null_space_residual: 0.01,
    };

    let result = twin.stress_test(&initial_state, &proposal);
    assert!(result.is_err(), "Divergent perturbation must fail stress test");
    match result.unwrap_err() {
        AdversarialError::DriftExceededThreshold { v_initial, v_diverged, threshold_limit } => {
            assert!(v_diverged > threshold_limit);
            assert!((threshold_limit - v_initial * 1.03).abs() < 1e-4);
        }
        _ => panic!("Expected DriftExceededThreshold error"),
    }
}

#[test]
fn test_nullspace_quadratic_residual_rejection() {
    let twin = AdversarialTwin::default_dim(2);
    let initial_state = sample_plant_state();

    // Modification with hidden quadratic non-linear error R_2 > 0.05
    let proposal = ModificationProposal {
        delta_theta: vec![0.001, 0.001],
        delta_coordinates: 1,
        proposed_state: initial_state.clone(),
        null_space_residual: 0.08, // Exceeds 0.05 bound
    };

    let result = twin.stress_test(&initial_state, &proposal);
    assert!(result.is_err());
    match result.unwrap_err() {
        AdversarialError::NullSpaceVulnerabilityDetected { quadratic_residual, max_allowed } => {
            assert_eq!(quadratic_residual, 0.08);
            assert_eq!(max_allowed, 0.05);
        }
        _ => panic!("Expected NullSpaceVulnerabilityDetected error"),
    }
}

#[test]
fn test_pre_commit_gate_fail_closed_veto() {
    let controller = ExternalController::new(ControllerConfig::default(), vec![1, 2, 3, 4]);
    let twin = AdversarialTwin::default_dim(2);
    let snapshot_store = SnapshotStore::new(vec![1, 2, 3, 4]);

    let mut gate = PreCommitGate::new(controller, twin, snapshot_store);
    let initial_state = sample_plant_state();

    // Malicious proposal with high residual and divergent delta
    let bad_proposal = ModificationProposal {
        delta_theta: vec![100.0, 100.0],
        delta_coordinates: 3,
        proposed_state: initial_state.clone(),
        null_space_residual: 0.12,
    };

    let commit_res = gate.evaluate_and_commit(&initial_state, bad_proposal);
    assert!(commit_res.is_err(), "Bad proposal must be rejected");
    // Verify fail-closed veto forced controller into HALT
    assert_eq!(gate.controller.mode, Mode::HALT);
}
