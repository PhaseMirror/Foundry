// crmf/tests/poseidon2_harness.rs
//! Test harness for Poseidon2 BN254 integration.

use crmf::poseidon2::Poseidon2Bn254Config;
use crmf::seal_event;
use num_rational::Ratio;

#[test]
fn test_constraint_budget_lock() {
    assert_eq!(Poseidon2Bn254Config::total_constraints(), 5_087);
}

#[test]
fn test_seal_event_output() {
    let ratio = Ratio::new(1, 2);
    let seal = seal_event(ratio);
    assert!(seal.starts_with("crmf_seal_bn254_"));
}
