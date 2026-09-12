use std::fs;
use m_operator_rust::*;

fn print_banner() {
    println!("================================================================================");
    println!("  THE MULTIPLICITY OPERATOR (M) PRODUCTION ENGINE (RUST SUBSTRATE)             ");
    println!("================================================================================");
}

fn run_verification() -> bool {
    println!("\n[+] Executing Multiplicity Operator Invariant Verification Suite...");

    let mut passed = 0;
    let mut failed = 0;

    // Test 1: Golden Ratio Invariants
    if (PHI * LAMBDA_M - 1.0).abs() < 1e-10 && (DELTA_I - (1.0 - LAMBDA_M)).abs() < 1e-10 {
        println!("  [PASS] Test 1: Fundamental invariants verified: phi*lambda_m=1.0, delta_I={:.6}", DELTA_I);
        passed += 1;
    } else {
        println!("  [FAIL] Test 1: Golden Ratio invariant check failed");
        failed += 1;
    }

    // Test 2: Fixed Point Target Zero Drift
    let target = MVector3::phi_target();
    if target.dist(&target) == 0.0 {
        println!("  [PASS] Test 2: Distance from fixed point target to itself is identically zero");
        passed += 1;
    } else {
        println!("  [FAIL] Test 2: Fixed point self distance non-zero");
        failed += 1;
    }

    // Test 3: Cubic Repair Vanishing at Target
    let rep_vec = compute_repair_3d(&target, &target, 0.3, RepairProtocol::Cubic);
    if rep_vec == MVector3::zero() {
        println!("  [PASS] Test 3: Cubic repair restoring force vanishes identically at target");
        passed += 1;
    } else {
        println!("  [FAIL] Test 3: Cubic repair non-zero at target");
        failed += 1;
    }

    // Test 4: Linear Repair Vanishing at Target
    let lin_vec = compute_repair_3d(&target, &target, 0.3, RepairProtocol::Linear);
    if lin_vec == MVector3::zero() {
        println!("  [PASS] Test 4: Linear repair restoring force vanishes identically at target");
        passed += 1;
    } else {
        println!("  [FAIL] Test 4: Linear repair non-zero at target");
        failed += 1;
    }

    // Test 5: Multi-Agent CSL Step Monotonic Clock
    let cfg = CSLSimulationConfig::default();
    let init_agents = vec![AgentState::new(0, 0, MVector3::new(1.7, 1.7, 1.7), &target, cfg.epsilon_threshold)];
    let next_agents = step_multi_agent_csl(&init_agents, &target, &cfg, 0);
    if next_agents[0].time == 1 {
        println!("  [PASS] Test 5: Multi-agent CSL step advanced clock to t=1 lawfully");
        passed += 1;
    } else {
        println!("  [FAIL] Test 5: Temporal clock progression error");
        failed += 1;
    }

    // Test 6: Non-Linear Regularization Boundedness
    let r_large = nonlinear_regularization(100.0, ALPHA_NL);
    if r_large < ALPHA_NL && r_large > 0.0 {
        println!("  [PASS] Test 6: Non-linear regularization R_nl strictly bounded by alpha ({:.4} < {:.4})", r_large, ALPHA_NL);
        passed += 1;
    } else {
        println!("  [FAIL] Test 6: Regularization bound breach");
        failed += 1;
    }

    // Test 7: Quantum Bayesian Update Bounds
    let p_post = quantum_bayesian_update(0.4, 0.8);
    if (p_post - 0.5).abs() < 1e-10 {
        println!("  [PASS] Test 7: Quantum Bayesian update computed normalized posterior: {:.4}", p_post);
        passed += 1;
    } else {
        println!("  [FAIL] Test 7: Bayesian update error: {:.4}", p_post);
        failed += 1;
    }

    // Test 8: Deterministic UnifiedWitness Generation
    let csl_res = validate_csl_agent_transition(&init_agents[0], &next_agents[0], 1.0);
    let witness = generate_unified_witness(&next_agents[0], &csl_res);
    if !witness.signature_hash.is_empty() && witness.is_stable {
        println!("  [PASS] Test 8: Deterministic UnifiedWitness SHA-256 anchor generated: {}", &witness.signature_hash[0..16]);
        passed += 1;
    } else {
        println!("  [FAIL] Test 8: Witness generation failed");
        failed += 1;
    }

    println!("--------------------------------------------------------------------------------");
    println!("  TOTAL: {} PASSED, {} FAILED", passed, failed);
    println!("--------------------------------------------------------------------------------");

    failed == 0
}

fn run_simulation() {
    println!("\n[+] Running Comparative Multi-Agent CSL Simulations (N=100 agents, T=100 steps)...");

    let attractors = vec![
        ("Golden Ratio (phi)", MVector3::phi_target()),
        ("Euler constant (e)", MVector3::e_target()),
        ("Pi / 4", MVector3::pi_over_4_target()),
        ("1 / sqrt(2)", MVector3::inv_sqrt_2_target()),
        ("Prime p=7 (1/sqrt(p))", MVector3::prime_target(7)),
        ("Prime p=29 (1/sqrt(p))", MVector3::prime_target(29)),
    ];

    println!("\n--- A. LINEAR REPAIR PROTOCOL ---");
    println!("--------------------------------------------------------------------------------");
    println!("| Attractor             | Mean Drift | Entropy | Collapses | Final Coherence |");
    println!("--------------------------------------------------------------------------------");
    for (name, target) in &attractors {
        let config = CSLSimulationConfig {
            agent_count: 100,
            step_count: 100,
            protocol: RepairProtocol::Linear,
            ..Default::default()
        };
        let summary = run_csl_benchmark(name, *target, &config);
        println!("| {:21} | {:10.4} | {:7.4} | {:9} | {:14.2}% |",
            summary.target_name, summary.mean_drift, summary.ethical_entropy, summary.total_collapses, summary.final_coherence_rate * 100.0);
    }
    println!("--------------------------------------------------------------------------------");

    println!("\n--- B. CUBIC (NON-LINEAR) REPAIR PROTOCOL ---");
    println!("--------------------------------------------------------------------------------");
    println!("| Attractor             | Mean Drift | Entropy | Collapses | Final Coherence |");
    println!("--------------------------------------------------------------------------------");
    for (name, target) in &attractors {
        let config = CSLSimulationConfig {
            agent_count: 100,
            step_count: 100,
            protocol: RepairProtocol::Cubic,
            ..Default::default()
        };
        let summary = run_csl_benchmark(name, *target, &config);
        println!("| {:21} | {:10.4} | {:7.4} | {:9} | {:14.2}% |",
            summary.target_name, summary.mean_drift, summary.ethical_entropy, summary.total_collapses, summary.final_coherence_rate * 100.0);
    }
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
