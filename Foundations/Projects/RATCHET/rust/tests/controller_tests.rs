use ratchet::controller::{ControllerConfig, ExternalController};
use ratchet::plant::ChaoticPlant;
use ratchet::types::Mode;

#[test]
fn test_idle_to_burst_transition() {
    let mut plant = ChaoticPlant::new();
    let mut controller = ExternalController::new(ControllerConfig::default(), b"test_key".to_vec());

    assert_eq!(controller.mode, Mode::IDLE);
    let mode = controller.step(&mut plant.state, 0.9, None, None, 1.0, 1.0, 0.0);
    assert_eq!(mode, Mode::BURST);
    assert_eq!(controller.mode, Mode::BURST);
    assert!(controller.last_snapshot_id.is_some());
}

#[test]
fn test_sandbox_breach_forces_halt_and_rollback() {
    let mut plant = ChaoticPlant::new();
    let mut controller = ExternalController::new(ControllerConfig::default(), b"test_key".to_vec());

    // Enter BURST
    controller.step(&mut plant.state, 0.9, None, None, 1.0, 1.0, 0.0);

    // Corrupt sandbox by introducing illegal huge actuation
    plant.state.u = vec![99999.0, 99999.0];

    // Trigger step; sandbox breach should force HALT
    let mode = controller.step(&mut plant.state, 0.9, None, None, 1.0, 1.0, 0.0);
    assert_eq!(mode, Mode::HALT);
    assert_eq!(controller.mode, Mode::HALT);
}

#[test]
fn test_nullspace_c3_pass_and_ground_admission() {
    let mut plant = ChaoticPlant::new();
    let mut config = ControllerConfig::default();
    config.max_burst_dwell = 2;
    config.ground_dwell = 2;
    let mut controller = ExternalController::new(config, b"test_key".to_vec());

    // IDLE -> BURST
    controller.step(&mut plant.state, 0.9, None, None, 1.0, 1.0, 0.0);

    // Step BURST until max_burst_dwell -> CAPTURE
    controller.step(&mut plant.state, 0.9, None, None, 1.0, 1.0, 0.0);
    let mode = controller.step(&mut plant.state, 0.9, None, None, 1.0, 1.0, 0.0);
    assert_eq!(mode, Mode::CAPTURE);

    // In CAPTURE, propose orthogonal candidate
    let z_new = vec![0.0, 1.0];
    let grad_phi = vec![1.0, 0.0];
    let mode = controller.step(
        &mut plant.state,
        0.9,
        Some(&z_new),
        Some(&grad_phi),
        1.0,
        1.1,
        0.1,
    );
    assert_eq!(mode, Mode::GROUND);

    // In GROUND, step through ground_dwell -> IDLE with receipt issued
    controller.step(&mut plant.state, 0.95, None, None, 1.0, 1.1, 0.1);
    let mode = controller.step(&mut plant.state, 0.95, None, None, 1.0, 1.1, 0.1);
    assert_eq!(mode, Mode::IDLE);
    assert_eq!(controller.issued_receipts.len(), 1);
    assert!(controller.issued_receipts[0].is_valid(plant.state.t));
}
