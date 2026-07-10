use governance_core_rs::{validate_quorum, CouncilRegistry, VotingRules, StandardRules, CouncilMember};
use serde_json::json;
use std::collections::HashMap;

#[test]
fn test_validate_quorum_basic() {
    let council = CouncilRegistry {
        members: vec![
            CouncilMember { id: "alice".to_string(), roles: vec!["safety".to_string()] },
            CouncilMember { id: "bob".to_string(), roles: vec!["legal".to_string()] },
            CouncilMember { id: "charlie".to_string(), roles: vec!["tech".to_string()] },
        ],
        voting_rules: VotingRules {
            standard: StandardRules { threshold: 2, required_roles: vec![] },
            critical: StandardRules { threshold: 2, required_roles: vec!["safety".to_string()] },
        },
    };

    let mut ledger = HashMap::new();
    ledger.insert("tx1".to_string(), json!({
        "governance_notes": "Approving ADR-AGI-001",
        "signers": ["alice", "bob"]
    }));
    ledger.insert("tx2".to_string(), json!({
        "governance_notes": "Approving ADR-AGI-002",
        "signers": ["alice", "charlie"]
    }));
    ledger.insert("tx3".to_string(), json!({
        "governance_notes": "Approving ADR-AGI-003",
        "signers": ["alice", "bob", "charlie"]
    }));
    ledger.insert("tx4".to_string(), json!({
        "governance_notes": "Approving ADR-AGI-004",
        "signers": ["alice", "bob"]
    }));

    let (ok, messages) = validate_quorum(&ledger, &council);
    assert!(ok, "Quorum should be met for all L0 ADRs. Messages: {:?}", messages);
}

#[test]
fn test_validate_quorum_missing_safety() {
    let council = CouncilRegistry {
        members: vec![
            CouncilMember { id: "alice".to_string(), roles: vec!["safety".to_string()] },
            CouncilMember { id: "bob".to_string(), roles: vec!["legal".to_string()] },
            CouncilMember { id: "charlie".to_string(), roles: vec!["tech".to_string()] },
        ],
        voting_rules: VotingRules {
            standard: StandardRules { threshold: 2, required_roles: vec![] },
            critical: StandardRules { threshold: 2, required_roles: vec!["safety".to_string()] },
        },
    };

    let mut ledger = HashMap::new();
    ledger.insert("tx1".to_string(), json!({
        "governance_notes": "Approving ADR-AGI-001",
        "signers": ["bob", "charlie"]
    }));

    let (ok, messages) = validate_quorum(&ledger, &council);
    assert!(!ok, "Should fail due to missing safety signature");
    assert!(messages.iter().any(|m| m.contains("Missing mandatory Safety Lead signature")));
}

#[test]
fn test_validate_quorum_insufficient_threshold() {
    let council = CouncilRegistry {
        members: vec![
            CouncilMember { id: "alice".to_string(), roles: vec!["safety".to_string()] },
            CouncilMember { id: "bob".to_string(), roles: vec!["legal".to_string()] },
            CouncilMember { id: "charlie".to_string(), roles: vec!["tech".to_string()] },
        ],
        voting_rules: VotingRules {
            standard: StandardRules { threshold: 2, required_roles: vec![] },
            critical: StandardRules { threshold: 2, required_roles: vec!["safety".to_string()] },
        },
    };

    let mut ledger = HashMap::new();
    ledger.insert("tx1".to_string(), json!({
        "governance_notes": "Approving ADR-AGI-001",
        "signers": ["alice"]
    }));

    let (ok, messages) = validate_quorum(&ledger, &council);
    assert!(!ok, "Should fail due to insufficient quorum");
    assert!(messages.iter().any(|m| m.contains("Quorum not met (1 < 2)")));
}
