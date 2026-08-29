use m_operator_rust::*;

#[test]
fn test_golden_ratio_identities() {
    assert!((PHI * LAMBDA_M - 1.0).abs() < 1e-10);
    assert!((PHI * PHI - (PHI + 1.0)).abs() < 1e-10);
    assert!((DELTA_I - (1.0 / (PHI * PHI))).abs() < 1e-10);
    assert!((DELTA_I - (1.0 - LAMBDA_M)).abs() < 1e-10);
}

#[test]
fn test_m_vector_geometry() {
    let v1 = MVector3::new(1.0, 2.0, 2.0);
    assert_eq!(v1.norm(), 3.0);

    let v2 = MVector3::new(4.0, 6.0, 2.0);
    assert_eq!(v1.dist(&v2), 5.0);

    let clamped = MVector3::new(50.0, -100.0, 10.0).clamp(20.0);
    assert_eq!(clamped.x, 20.0);
    assert_eq!(clamped.y, -20.0);
    assert_eq!(clamped.z, 10.0);
}

#[test]
fn test_nonlinear_regularization_asymptote() {
    let r0 = nonlinear_regularization(0.0, 0.5);
    assert_eq!(r0, 0.0);

    let r1 = nonlinear_regularization(1.0, 0.5);
    assert_eq!(r1, 0.25); // 0.5 * 1 / 2 = 0.25

    let r_large = nonlinear_regularization(1000.0, 0.5);
    assert!(r_large < 0.5);
    assert!(r_large > 0.499);
}

#[test]
fn test_evaluate_m_operator_prime_scaling() {
    let out3 = evaluate_m_operator(1.0, 3, 0.0, 0);
    let out7 = evaluate_m_operator(1.0, 7, 0.0, 0);
    let out13 = evaluate_m_operator(1.0, 13, 0.0, 0);

    assert!(out7.total_transformed_value > out3.total_transformed_value);
    assert!(out13.total_transformed_value > out7.total_transformed_value);
}

#[test]
fn test_cubic_repair_dynamics_convergence() {
    let target = MVector3::phi_target();
    let config = CSLSimulationConfig {
        agent_count: 20,
        step_count: 50,
        protocol: RepairProtocol::Cubic,
        ..Default::default()
    };

    let summary = run_csl_benchmark("Phi", target, &config);
    assert!(summary.mean_drift < 1.0);
    assert!(summary.ethical_entropy >= 0.0);
}

#[test]
fn test_peer_to_peer_coupling_symmetry() {
    let target = MVector3::phi_target();
    let a0 = AgentState::new(0, 0, MVector3::new(1.0, 1.0, 1.0), &target, 0.05);
    let a1 = AgentState::new(1, 0, MVector3::new(2.0, 2.0, 2.0), &target, 0.05);
    let a2 = AgentState::new(2, 0, MVector3::new(3.0, 3.0, 3.0), &target, 0.05);

    let agents = vec![a0, a1, a2];
    let coupling1 = compute_peer_coupling(&agents, 1, 0.1);

    // Agent 1 has neighbors a0 (1,1,1) and a2 (3,3,3). Midpoint is (2,2,2), so net force is 0.
    assert!(coupling1.norm() < 1e-10);
}

#[test]
fn test_quantum_bayesian_update_correctness() {
    let p = quantum_bayesian_update(0.35, 0.70);
    assert!((p - 0.5).abs() < 1e-10);

    let p_zero = quantum_bayesian_update(0.0, 0.5);
    assert_eq!(p_zero, 0.0);
}

#[test]
fn test_qmi_unitary_evolution_norm_preservation() {
    let st0 = QBNState::new_2qubit();
    let st1 = qmi_step(&st0, 0.5);

    let total_norm_sq: f64 = st1.amplitudes.iter().map(|a| a.norm_sq()).sum();
    assert!((total_norm_sq - 1.0).abs() < 1e-10, "Quantum state must remain normalized to 1.0");
}

#[test]
fn test_deterministic_unified_witness() {
    let target = MVector3::phi_target();
    let st = AgentState::new(7, 42, MVector3::new(1.618, 1.618, 1.618), &target, 0.05);
    let csl_res = CSLValidationResult {
        is_lawful: true,
        reason: "Valid".to_string(),
        witness_digest: "CSL_WITNESS_VERIFIED_STABLE".to_string(),
    };

    let w1 = generate_unified_witness(&st, &csl_res);
    let w2 = generate_unified_witness(&st, &csl_res);

    assert_eq!(w1.signature_hash, w2.signature_hash);
    assert_eq!(w1.time, 42);
    assert!(w1.is_stable);
}

#[test]
fn test_subsystem_certificate_structure() {
    let cert = SubsystemCertificate::new_ratified();
    assert_eq!(cert.subsystem, "M_OPERATOR");
    assert_eq!(cert.status, "RATIFIED_AXIOM_CLEAN");
    assert_eq!(cert.lean_verification.theorems_proven.len(), 10);
    assert_eq!(cert.rust_engine.test_status, "SUCCESS (10 passed, 0 failed)");
}
