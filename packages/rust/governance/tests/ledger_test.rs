use governance_core_rs::{AuditLedger, AuditLedgerEntry, LedgerEntryType};
use serde_json::json;
use tempfile::tempdir;

#[test]
fn test_audit_ledger_hash_chain() {
    let mut ledger = AuditLedger::new(None).unwrap();
    
    let entry1 = ledger.append(json!({"data": "first"}), None, None, false).unwrap();
    let entry2 = ledger.append(json!({"data": "second"}), None, None, false).unwrap();
    
    assert_eq!(entry1.sequence_num, 1);
    assert_eq!(entry2.sequence_num, 2);
    assert_eq!(entry2.prev_hash, entry1.entry_hash);
    assert_ne!(entry1.entry_hash, entry2.entry_hash);
}

#[test]
fn test_append_proof_anchor() {
    let mut ledger = AuditLedger::new(None).unwrap();
    let anchor = "0x0000000000000000000000000000000000000000000000000000000000000001";
    let entry = ledger.append_proof_anchor(anchor, "circuit-1", "prop-1").unwrap();
    
    assert_eq!(entry.proof_anchor, Some(anchor.to_string()));
    assert_eq!(entry.report["kind"], "PROOF_ANCHOR");
}

#[test]
fn test_audit_ledger_validation() {
    let mut ledger = AuditLedger::new(None).unwrap();
    ledger.append(json!({"data": "first"}), None, None, false).unwrap();
    ledger.append(json!({"data": "second"}), None, None, false).unwrap();
    
    assert!(ledger.validate());
    
    // Corrupt an entry
    ledger.entries[0].payload_hash = "corrupted".to_string();
    assert!(!ledger.validate());
}
