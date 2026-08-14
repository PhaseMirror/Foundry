use governance_core_rs::self_modification::*;
use serde_json::json;

#[test]
fn test_modification_proposal_hash() {
    let prop = ModificationProposal::new(
        "prop-1".to_string(),
        ModificationTarget::GainMatrix,
        "snap-1".to_string(),
        json!({"delta": 1}),
        "rationale".to_string(),
    );
    
    let hash = prop.proposal_hash();
    assert!(!hash.is_empty());
}

#[test]
fn test_boundary_gate() {
    let mut prop = ModificationProposal::new(
        "prop-1".to_string(),
        ModificationTarget::GainMatrix,
        "snap-1".to_string(),
        json!({}),
        "".to_string(),
    );
    prop.reversibility = Reversibility::Irreversible;
    
    let boundary_doc = json!({"safe_to_transfer_pattern": false});
    let (ok, blockers) = check_boundary_gate(&prop, &boundary_doc);
    assert!(!ok);
    assert!(blockers[0].contains("requires safe_to_transfer_pattern=true"));
}

#[test]
fn test_legitimacy_gate() {
     let prop = ModificationProposal::new(
        "prop-1".to_string(),
        ModificationTarget::LegitimacyDocument,
        "snap-1".to_string(),
        json!({}),
        "".to_string(),
    );
    
    let legitimacy_doc = json!({
        "input_legitimacy": "ok",
        "procedural_legitimacy": "ok",
        "output_legitimacy": "ok",
        "tradeoff_declaration": {"approver": "council"}
    });
    
    // Human approval mandatory for LegitimacyDocument target
    let (ok, blockers) = check_legitimacy_gate(&prop, &legitimacy_doc, false);
    assert!(!ok);
    assert!(blockers[0].contains("human approval is mandatory"));
    
    let (ok2, _) = check_legitimacy_gate(&prop, &legitimacy_doc, true);
    assert!(ok2);
}
