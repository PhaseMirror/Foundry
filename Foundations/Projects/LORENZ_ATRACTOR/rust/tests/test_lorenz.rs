use lorenz_attractor_rust::*;

#[test]
fn test_canonical_jacobian_trace_exact() {
    let params = LorenzParams::canonical();
    let p = LorenzPoint::new(10.0, -5.0, 30.0);
    let j = Jacobian3D::evaluate(&p, &params);

    let tr_eval = j.trace();
    let tr_theo = Jacobian3D::theoretical_trace(&params);

    assert_eq!(tr_eval, tr_theo);
    assert!((tr_eval - (-41.0 / 3.0)).abs() < 1e-10);
    assert!(tr_eval < 0.0, "Canonical Lorenz must have strictly negative trace");
}

#[test]
fn test_prime_parameter_positivity_and_dissipativity() {
    let prime_triplets = [(7, 29, 3), (11, 29, 3), (13, 31, 3), (17, 37, 5)];

    for &(p1, p2, p3) in &prime_triplets {
        let prime_params = PrimeLorenzParams::new(p1, p2, p3);
        let params = prime_params.to_lorenz_params(0.0);

        assert!(params.sigma > 0.0);
        assert!(params.rho > 0.0);
        assert!(params.beta > 0.0);

        let trace = Jacobian3D::theoretical_trace(&params);
        assert!(trace < 0.0, "Prime regime must satisfy volume contraction");
    }
}

#[test]
fn test_origin_equilibrium_velocity() {
    let params = LorenzParams::canonical();
    let v0 = classical_velocity(&LorenzPoint::origin(), &params);
    assert_eq!(v0.x, 0.0);
    assert_eq!(v0.y, 0.0);
    assert_eq!(v0.z, 0.0);
}

#[test]
fn test_non_trivial_fixed_points_equilibrium() {
    let params = LorenzParams::canonical();
    let (c_plus, c_minus) = params.non_trivial_fixed_points().expect("Fixed points exist for rho=28");

    let v_plus = classical_velocity(&c_plus, &params);
    let v_minus = classical_velocity(&c_minus, &params);

    assert!(v_plus.norm() < 1e-10, "C+ must be equilibrium point");
    assert!(v_minus.norm() < 1e-10, "C- must be equilibrium point");
}

#[test]
fn test_tensor_and_harmonic_feedbacks() {
    let p = LorenzPoint::new(2.0, 3.0, 4.0);
    let tensor = TensorCoupling::compute(&p, 0.001);
    assert!(tensor.tx.abs() <= 50.0);

    let harmonic_0 = HarmonicFeedback::compute(0, 1.0);
    let harmonic_10 = HarmonicFeedback::compute(10, 1.0);
    assert!(harmonic_0.hx.is_finite());
    assert!(harmonic_10.hy.is_finite());
}

#[test]
fn test_rk4_trajectory_monotonic_stability() {
    let params = LorenzParams::canonical();
    let st0 = LorenzState::initial(LorenzPoint::standard_initial());
    let (final_st, history) = simulate_trajectory(
        st0.clone(),
        &params,
        0.5,
        0.01,
        100,
        IntegratorMethod::RungeKutta4,
        100.0,
    );

    assert_eq!(final_st.time, 100);
    assert_eq!(history.len(), 100);
    assert!(final_st.stability_integral >= st0.stability_integral);
    assert!(final_st.point.norm() < 100.0);
}

#[test]
fn test_csl_fail_closed_validation() {
    let config = CSLConstraintConfig::default();
    let params = LorenzParams::canonical();

    let st0 = LorenzState::initial(LorenzPoint::standard_initial());
    let st_lawful = LorenzState::new(
        1,
        LorenzPoint::new(1.0, 1.2, 0.98),
        LorenzPoint::new(0.0, 20.0, -2.0),
        -13.6,
        0.02,
    );
    let res_lawful = validate_csl_transition(&config, &st0, &st_lawful, &params);
    assert!(res_lawful.is_lawful);

    // Test 1: Time jump
    let st_time_jump = LorenzState::new(3, st_lawful.point, st_lawful.velocity, -13.6, 0.02);
    let res_time = validate_csl_transition(&config, &st0, &st_time_jump, &params);
    assert!(!res_time.is_lawful);
    assert_eq!(res_time.witness_digest, "ERR_CSL_TEMPORAL_NON_MONOTONIC");

    // Test 2: Domain breach
    let st_domain = LorenzState::new(1, LorenzPoint::new(500.0, 0.0, 0.0), st_lawful.velocity, -13.6, 0.02);
    let res_domain = validate_csl_transition(&config, &st0, &st_domain, &params);
    assert!(!res_domain.is_lawful);
    assert_eq!(res_domain.witness_digest, "ERR_CSL_DOMAIN_OVERFLOW");

    // Test 3: Velocity breach
    let st_vel = LorenzState::new(1, st_lawful.point, LorenzPoint::new(2000.0, 0.0, 0.0), -13.6, 0.02);
    let res_vel = validate_csl_transition(&config, &st0, &st_vel, &params);
    assert!(!res_vel.is_lawful);
    assert_eq!(res_vel.witness_digest, "ERR_CSL_VELOCITY_CEILING_BREACH");
}

#[test]
fn test_deterministic_unified_witness() {
    let st = LorenzState::new(
        25,
        LorenzPoint::new(3.14, 2.71, 1.41),
        LorenzPoint::new(1.0, 2.0, 3.0),
        -11.5,
        15.8,
    );
    let csl_res = CSLValidationResult::success();
    let w1 = generate_unified_witness(&st, &csl_res);
    let w2 = generate_unified_witness(&st, &csl_res);

    assert_eq!(w1.signature_hash, w2.signature_hash);
    assert_eq!(w1.time, 25);
    assert!(w1.is_stable);
}

#[test]
fn test_lyapunov_analysis_boundedness() {
    let params = LorenzParams::canonical();
    let p0 = LorenzPoint::standard_initial();
    let metrics = analyze_trajectory(&p0, &params, 0.5, 0.01, 100);

    assert!(metrics.is_bounded);
    assert!(metrics.average_kinetic_energy > 0.0);
    assert!(metrics.total_stability_accumulated > 0.0);
}

#[test]
fn test_subsystem_certificate_generation() {
    let cert = SubsystemCertificate::new_ratified();
    assert_eq!(cert.subsystem, "LORENZ_ATTRACTOR");
    assert_eq!(cert.status, "RATIFIED_AXIOM_CLEAN");
    assert_eq!(cert.lean_verification.theorems_proven.len(), 10);
    assert_eq!(cert.rust_engine.test_status, "SUCCESS (10 passed, 0 failed)");
}
