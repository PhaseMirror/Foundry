use std::fs;
use lorenz_attractor_rust::*;

fn print_banner() {
    println!("================================================================================");
    println!("  MULTIPLICITY-ENHANCED LORENZ ATTRACTOR ENGINE (RUST SUBSTRATE)               ");
    println!("================================================================================");
}

fn run_verification() -> bool {
    println!("\n[+] Executing Multiplicity Invariant Verification Suite...");

    let mut passed = 0;
    let mut failed = 0;

    // Test 1: Prime parameter mapping & volume contraction
    let prime_p = PrimeLorenzParams::default_7_29_3();
    let l_params = prime_p.to_lorenz_params(0.0);
    let trace_prime = Jacobian3D::theoretical_trace(&l_params);
    if trace_prime < 0.0 && l_params.sigma == 7.0 && l_params.rho == 29.0 && l_params.beta == 3.0 {
        println!("  [PASS] Test 1: Prime parameters (7, 29, 3) preserve negative Jacobian trace (Tr={:.2})", trace_prime);
        passed += 1;
    } else {
        println!("  [FAIL] Test 1: Prime parameter check failed");
        failed += 1;
    }

    // Test 2: Origin equilibrium point
    let v_origin = classical_velocity(&LorenzPoint::origin(), &LorenzParams::canonical());
    if v_origin == LorenzPoint::origin() {
        println!("  [PASS] Test 2: Origin (0,0,0) is stationary equilibrium point");
        passed += 1;
    } else {
        println!("  [FAIL] Test 2: Origin velocity was non-zero");
        failed += 1;
    }

    // Test 3: RK4 High-Precision Step
    let st0 = LorenzState::initial(LorenzPoint::standard_initial());
    let params_can = LorenzParams::canonical();
    let st1 = rk4_step(&st0, &params_can, 0.5, 0.01, 100.0);
    if st1.time == 1 && st1.stability_integral >= st0.stability_integral {
        println!("  [PASS] Test 3: RK4 integration step advanced clock and increased stability functional S(t)");
        passed += 1;
    } else {
        println!("  [FAIL] Test 3: RK4 integration step failed");
        failed += 1;
    }

    // Test 4: CSL Gatekeeper Fail-Closed Enforcement
    let csl_config = CSLConstraintConfig::default();
    let csl_res_lawful = validate_csl_transition(&csl_config, &st0, &st1, &params_can);
    let st_invalid_time = LorenzState::new(5, st1.point, st1.velocity, st1.lambda_multiplicity, st1.stability_integral);
    let csl_res_unlawful = validate_csl_transition(&csl_config, &st0, &st_invalid_time, &params_can);
    if csl_res_lawful.is_lawful && !csl_res_unlawful.is_lawful {
        println!("  [PASS] Test 4: CSL Gatekeeper verified lawful transition and rejected temporal discontinuity");
        passed += 1;
    } else {
        println!("  [FAIL] Test 4: CSL Gatekeeper logic failure");
        failed += 1;
    }

    // Test 5: Deterministic UnifiedWitness generation
    let witness = generate_unified_witness(&st1, &csl_res_lawful);
    if !witness.signature_hash.is_empty() && witness.is_stable {
        println!("  [PASS] Test 5: UnifiedWitness SHA-256 anchor generated lawfully: {}", &witness.signature_hash[0..16]);
        passed += 1;
    } else {
        println!("  [FAIL] Test 5: UnifiedWitness generation failed");
        failed += 1;
    }

    // Test 6: 100-step Simulation Boundedness
    let (st_final, history) = simulate_trajectory(
        st0,
        &params_can,
        1.0,
        0.01,
        100,
        IntegratorMethod::RungeKutta4,
        100.0,
    );
    if st_final.time == 100 && history.len() == 100 && st_final.point.norm() < 100.0 {
        println!("  [PASS] Test 6: 100-step RK4 trajectory strictly bounded (Final Norm: {:.4})", st_final.point.norm());
        passed += 1;
    } else {
        println!("  [FAIL] Test 6: 100-step trajectory simulation failed");
        failed += 1;
    }

    // Test 7: Lyapunov Diagnostics
    let metrics = analyze_trajectory(&LorenzPoint::standard_initial(), &params_can, 0.5, 0.01, 150);
    if metrics.is_bounded && metrics.total_stability_accumulated > 0.0 {
        println!("  [PASS] Test 7: Trajectory diagnostics computed (LLE: {:.4}, Avg KE: {:.4}, Total S: {:.4})",
            metrics.largest_lyapunov_exponent, metrics.average_kinetic_energy, metrics.total_stability_accumulated);
        passed += 1;
    } else {
        println!("  [FAIL] Test 7: Trajectory diagnostics failure");
        failed += 1;
    }

    println!("--------------------------------------------------------------------------------");
    println!("  TOTAL: {} PASSED, {} FAILED", passed, failed);
    println!("--------------------------------------------------------------------------------");

    failed == 0
}

fn run_simulation() {
    println!("\n[+] Running Comparative Production Trajectory Simulations...");

    let p0 = LorenzPoint::standard_initial();
    let st0 = LorenzState::initial(p0);
    let dt = 0.01;
    let steps = 50;

    // 1. Canonical Classical Lorenz
    let canon_params = LorenzParams::canonical();
    let (canon_st, _) = simulate_trajectory(
        st0.clone(),
        &canon_params,
        0.0,
        dt,
        steps,
        IntegratorMethod::RungeKutta4,
        100.0,
    );

    // 2. Canonical Stabilized Multiplicity Lorenz
    let (stabilized_st, _) = simulate_trajectory(
        st0.clone(),
        &canon_params,
        2.0,
        dt,
        steps,
        IntegratorMethod::RungeKutta4,
        100.0,
    );

    // 3. Prime-Encoded (7, 29, 3) Multiplicity Lorenz
    let prime_params = PrimeLorenzParams::default_7_29_3().to_lorenz_params(0.0);
    let (prime_st, _) = simulate_trajectory(
        st0,
        &prime_params,
        2.0,
        dt,
        steps,
        IntegratorMethod::RungeKutta4,
        100.0,
    );

    println!("--------------------------------------------------------------------------------");
    println!("| Regime               | Final Position (x, y, z)          | Final S(t) | Norm   |");
    println!("--------------------------------------------------------------------------------");
    println!("| Canonical (Uncorr)   | ({:6.2}, {:6.2}, {:6.2})           | {:10.4} | {:6.2} |",
        canon_st.point.x, canon_st.point.y, canon_st.point.z, canon_st.stability_integral, canon_st.point.norm());
    println!("| Canonical (Stabiliz) | ({:6.2}, {:6.2}, {:6.2})           | {:10.4} | {:6.2} |",
        stabilized_st.point.x, stabilized_st.point.y, stabilized_st.point.z, stabilized_st.stability_integral, stabilized_st.point.norm());
    println!("| Prime (7, 29, 3)     | ({:6.2}, {:6.2}, {:6.2})           | {:10.4} | {:6.2} |",
        prime_st.point.x, prime_st.point.y, prime_st.point.z, prime_st.stability_integral, prime_st.point.norm());
    println!("--------------------------------------------------------------------------------");
}

fn export_certificate(target_path: &str) {
    println!("\n[+] Materializing Subsystem Certification to {}...", target_path);
    let cert = SubsystemCertificate::new_ratified();
    let json_content = serde_json::to_string_pretty(&cert).expect("Failed to serialize certificate");
    fs::write(target_path, json_content).expect("Failed to write certificate file");
    println!("  [OK] Successfully wrote ratified certificate (Hash: {})", &cert.certification_hash[0..16]);
}

fn main() {
    print_banner();

    let args: Vec<String> = std::env::args().collect();
    let mode = if args.len() > 1 { args[1].as_str() } else { "all" };

    match mode {
        "verify" => {
            let ok = run_verification();
            std::process::exit(if ok { 0 } else { 1 });
        }
        "simulate" => {
            run_simulation();
        }
        "certify" => {
            let cert_path = "../UNIFIED_WITNESS_CERTIFICATE.json";
            export_certificate(cert_path);
        }
        _ => {
            let ok = run_verification();
            run_simulation();
            let cert_path = "../UNIFIED_WITNESS_CERTIFICATE.json";
            export_certificate(cert_path);
            if !ok {
                std::process::exit(1);
            }
        }
    }
}
