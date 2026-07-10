use ace_zk::csc::CanonicalCircuitBudget;

#[test]
fn poseidon2_parameters_are_locked() {
    assert_eq!(CanonicalCircuitBudget::REQUIRED_T, 9);
    assert_eq!(CanonicalCircuitBudget::REQUIRED_R, 8);
}

#[test]
fn canonical_cost_buckets_match_patent_budget() {
    assert_eq!(CanonicalCircuitBudget::COST_FWHT, 384);
    assert_eq!(CanonicalCircuitBudget::COST_POSEIDON_H, 3171);
    assert_eq!(CanonicalCircuitBudget::COST_POSEIDON_GAMMA, 1500);
    assert_eq!(CanonicalCircuitBudget::COST_RANGE, 32);
    assert_eq!(CanonicalCircuitBudget::CANONICAL_TOTAL, 5087);
}

#[test]
fn circom_files_reference_locked_topology() {
    let ace = include_str!("../circuits/ace.circom");
    let constraints = include_str!("../circuits/constraints.circom");
    let poseidon = include_str!("../circuits/poseidon2.circom");

    assert!(ace.contains("component poseidon_lock = Poseidon2TopologyLock();"));
    assert!(ace.contains("poseidon_lock.t <== 9;"));
    assert!(ace.contains("poseidon_lock.r <== 8;"));

    assert!(constraints.contains("fwht_cost <== 384;"));
    assert!(constraints.contains("poseidon_h_cost <== 3171;"));
    assert!(constraints.contains("poseidon_gamma_cost <== 1500;"));
    assert!(constraints.contains("range_cost <== 32;"));
    assert!(constraints.contains("total_cost === 5087;"));

    assert!(poseidon.contains("t - 9"));
    assert!(poseidon.contains("r - 8"));
}

#[test]
fn compiler_output_must_match_canonical_total() {
    assert!(CanonicalCircuitBudget::enforce_compiler_target(5087).is_ok());
    assert!(CanonicalCircuitBudget::enforce_compiler_target(5086).is_err());
}
