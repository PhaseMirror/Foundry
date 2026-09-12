use ratchet::attacks::{AttackResult, RedTeamHarness};

#[test]
fn test_all_seven_attacks_blocked() {
    let harness = RedTeamHarness::new(5);
    let results = harness.run_full_suite();

    assert_eq!(results.len(), 7);
    for (num, name, result) in results {
        match result {
            AttackResult::Blocked { mitigation } => {
                println!("Passed attack test {}: {} -> {}", num, name, mitigation);
            }
            AttackResult::Unblocked { vulnerability } => {
                panic!("Vulnerability detected on attack {}: {} -> {}", num, name, vulnerability);
            }
        }
    }
}
