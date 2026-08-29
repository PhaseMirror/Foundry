use langlands_prism_rust::*;

#[test]
fn test_prime_sieve_and_dirichlet_characters() {
    let p8 = first_n_primes(8);
    assert_eq!(p8, vec![2, 3, 5, 7, 11, 13, 17, 19]);

    // Dirichlet character mod 4 checks
    assert_eq!(dirichlet_char_4(1), 1);
    assert_eq!(dirichlet_char_4(2), 0);
    assert_eq!(dirichlet_char_4(3), -1);
    assert_eq!(dirichlet_char_4(5), 1);
    assert_eq!(dirichlet_char_4(7), -1);

    // Euler factors at s=1
    let ef_5 = dirichlet_euler_factor(5, 1.0, 1);
    assert!((ef_5 - 1.25).abs() < 1e-6);

    let ef_3 = dirichlet_euler_factor(3, 1.0, -1);
    assert!((ef_3 - 0.75).abs() < 1e-6);
}

#[test]
fn test_pirtm_tensor_cascade_and_stability() {
    let primes = [2, 3, 5, 7, 11];
    let st0 = PrismTensorState::new_with_primes(&primes, LAMBDA_M);
    assert_eq!(st0.nodes.len(), 5);
    assert_eq!(st0.time, 0);

    let mut curr = st0.clone();
    for _ in 0..10 {
        curr = curr.step();
        assert!(curr.is_stable);
        assert!(curr.coherence >= 0.0 && curr.coherence <= 1.0);
        assert!(curr.total_energy() <= 5.0);
    }
    assert_eq!(curr.time, 10);
}

#[test]
fn test_quantum_fractal_superposition() {
    let primes = [2, 3, 5, 7];
    let st0 = PrismTensorState::new_with_primes(&primes, LAMBDA_M);
    let fractal_st = st0.fractal_superposition(4);

    assert_eq!(fractal_st.nodes.len(), 4);
    for (n_orig, n_frac) in st0.nodes.iter().zip(fractal_st.nodes.iter()) {
        assert!(n_frac.weight >= n_orig.weight);
    }
}

#[test]
fn test_galois_group_actions_and_duality() {
    let primes = [2, 3, 5, 7, 11];
    let st0 = PrismTensorState::new_with_primes(&primes, LAMBDA_M);

    // Permutation action
    let perm = apply_galois_action(&st0, &GaloisAction::PrimePermute { i: 0, j: 4 });
    assert_eq!(perm.nodes[0].prime, 11);
    assert_eq!(perm.nodes[4].prime, 2);

    // Langlands Dual Tensor
    let dual = compute_langlands_dual_tensor(&st0);
    assert_eq!(dual.nodes.len(), 5);

    let fidelity = entanglement_fidelity(&st0, &dual);
    assert!(fidelity >= 0.0 && fidelity <= 1.0);

    // Gravitational wave amplitude calculation
    let g_wave = gravitational_wave_modulation(&st0);
    assert!(!g_wave.is_nan());
}

#[test]
fn test_dynamic_operator_commutator_and_shock_recovery() {
    let initial_shock = SemanticVector::new(vec![0.90, 0.90, 0.90, 0.90]);
    let target = SemanticVector::equilibrium(4);
    let trajectory = simulate_shock_recovery(&initial_shock, &target, 12);

    let d_init = trajectory[0].1;
    let d_final = trajectory[trajectory.len() - 1].1;

    assert!(d_final < d_init);
    assert!(d_final < 0.02, "Expected exponential decay to < 0.02, got {}", d_final);
}

#[test]
fn test_marcl_multiagent_shock_and_trust_reallocation() {
    let mut cluster = MARCLCluster::new_4agents();
    let shock = SemanticVector::new(vec![0.95, 0.95, 0.95, 0.95]);
    cluster.inject_shock(3, shock);

    assert_eq!(cluster.agents[3].regret, 0.8);
    assert!(cluster.agents[3].resilience < 0.5);

    // Evolve 1 step -> trust should drop
    let step1 = cluster.step();
    assert!(step1.trust_matrix[0][3] < cluster.trust_matrix[0][3]);

    // Evolve 10 steps -> recovery
    let recovered = step1.iterate(10);
    assert!(recovered.agents[3].regret < 0.2);
    assert!(recovered.agents[3].resilience > 0.6);
}

#[test]
fn test_godelian_accountability_ledger_accumulation() {
    let cluster = MARCLCluster::new_4agents();
    let evolved = cluster.iterate(5);

    let mut total_flow = 0.0;
    for row in &evolved.godelian_ledger {
        for &val in row {
            total_flow += val.abs();
        }
    }
    assert!(total_flow > 0.0, "Godelian ledger must record non-zero audit flow");
}

#[test]
fn test_ethical_firewall_and_automated_collapse() {
    let primes = [2, 3, 5, 7, 11];
    let safe_st = PrismTensorState::new_with_primes(&primes, LAMBDA_M);
    let (gated_st, was_triggered) = firewall_gate(&safe_st);
    assert!(!was_triggered);
    assert!(compute_ethical_metric(&gated_st) <= ETHICAL_THRESHOLD);

    // Simulated overflow state
    let breach_nodes = vec![
        TensorNode::new(2, 1.0, 1.5, 1.0),
        TensorNode::new(3, 1.0, 1.5, 1.0),
        TensorNode::new(5, 1.0, 1.5, 1.0),
    ];
    let breach_st = PrismTensorState {
        time: 0,
        lambda_m: LAMBDA_M,
        nodes: breach_nodes,
        coherence: 0.2,
        is_stable: true,
    };

    let (quenched_st, triggered_collapse) = firewall_gate(&breach_st);
    assert!(triggered_collapse);
    assert!(compute_ethical_metric(&quenched_st) < ETHICAL_THRESHOLD);
}

#[test]
fn test_cryptographic_provenance_ledger_integrity() {
    let mut ledger = ProvenanceLedger::new();
    let primes = [2, 3, 5, 7, 11];
    let mut st = PrismTensorState::new_with_primes(&primes, LAMBDA_M);

    for _ in 0..5 {
        ledger.record_state(&st);
        st = st.step();
    }

    assert_eq!(ledger.blocks.len(), 5);
    assert!(ledger.verify_chain_integrity());

    // Tamper test
    let mut tampered_ledger = ledger.clone();
    tampered_ledger.blocks[2].state_hash = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff".to_string();
    assert!(!tampered_ledger.verify_chain_integrity());
}

#[test]
fn test_quantum_circuit_qasm_synthesis() {
    let primes = [2, 3, 5, 7, 11];
    let st = PrismTensorState::new_with_primes(&primes, LAMBDA_M);
    let qc = QuantumLanglandsCircuit::from_tensor_state(&st);

    assert_eq!(qc.num_qubits, 5);
    let qasm = qc.to_openqasm();
    assert!(qasm.contains("OPENQASM 2.0;"));
    assert!(qasm.contains("qreg q[5];"));
    assert!(qasm.contains("creg c[5];"));
    assert!(qasm.contains("h q[0];"));
    assert!(qasm.contains("measure q -> c;"));
}

#[test]
fn test_unified_witness_creation_and_serialization() {
    let primes = [2, 3, 5, 7, 11];
    let st = PrismTensorState::new_with_primes(&primes, LAMBDA_M);
    let marcl = MARCLCluster::new_4agents();
    let mut ledger = ProvenanceLedger::new();
    ledger.record_state(&st);

    let witness = UnifiedWitness::build(&st, &marcl, &ledger, 0.008);
    assert!(witness.is_verified);
    assert_eq!(witness.prime_basis, vec![2, 3, 5, 7, 11]);

    let json = witness.to_json_pretty();
    assert!(json.contains("The Langlands Prism"));
    assert!(json.contains("ENFORCED_AND_SAFE"));
}
