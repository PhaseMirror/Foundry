//! Integration tests for the ADR Rust crate ensuring core invariants.

use std::collections::HashMap;

use adr_rust::{example_adrs, Adr, AdrError, AdrId, AdrStatus};

#[test]
fn test_accepted_immutable() {
    let mut adr = Adr::new(
        10,
        "Test immutable",
        "ctx",
        "dec",
        vec![],
        vec![],
    );
    // Accept the ADR
    adr.transition(AdrStatus::Accepted, None).unwrap();
    // Trying to deprecate after acceptance should fail
    assert_eq!(adr.transition(AdrStatus::Deprecated, None), Err(AdrError::ImmutableAccepted));
}

#[test]
fn test_supersession_cycle_detection() {
    // Build a registry with a cycle: 1 -> 2 -> 1
    let mut reg: HashMap<AdrId, Adr> = HashMap::new();
    let mut adr1 = Adr::new(1, "A", "c", "d", vec![], vec![]);
    let mut adr2 = Adr::new(2, "B", "c", "d", vec![], vec![]);
    // Set supersession manually to create a cycle
    adr1.supersedes = Some(2);
    adr2.supersedes = Some(1);
    reg.insert(1, adr1.clone());
    reg.insert(2, adr2.clone());
    // Validation should detect a cycle on either ADR
    assert_eq!(adr1.validate_acyclic(&reg), Err(AdrError::CycleDetected));
    assert_eq!(adr2.validate_acyclic(&reg), Err(AdrError::CycleDetected));
}

#[test]
fn test_history_reconstruction() {
    // Build a chain: 3 supersedes 2 supersedes 1
    let mut reg: HashMap<AdrId, Adr> = HashMap::new();
    let mut adr1 = Adr::new(1, "First", "c", "d", vec![], vec![]);
    let mut adr2 = Adr::new(2, "Second", "c", "d", vec![], vec![]);
    let mut adr3 = Adr::new(3, "Third", "c", "d", vec![], vec![]);
    adr2.supersedes = Some(1);
    adr3.supersedes = Some(2);
    reg.insert(1, adr1.clone());
    reg.insert(2, adr2.clone());
    reg.insert(3, adr3.clone());
    let hist = adr3.history(&reg);
    assert_eq!(hist, vec![3, 2, 1]);
}

#[test]
fn test_example_adrs_validity() {
    let examples = example_adrs();
    // Build a simple registry from the examples
    let mut reg: HashMap<AdrId, Adr> = HashMap::new();
    for adr in &examples {
        reg.insert(adr.id, adr.clone());
    }
    // Validate each example's acyclicity and that Accepted ones are immutable unless superseded
    for adr in examples {
        // Should be acyclic
        assert!(adr.validate_acyclic(&reg).is_ok());
        // If Accepted, ensure transition to Deprecated fails
        if adr.status == AdrStatus::Accepted {
            let mut a = adr.clone();
            assert_eq!(a.transition(AdrStatus::Deprecated, None), Err(AdrError::ImmutableAccepted));
        }
    }
}
