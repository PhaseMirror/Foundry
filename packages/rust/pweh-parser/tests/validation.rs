use pweh_parser::{PwehReceipt, validate_receipt};

#[test]
fn test_valid_receipt() {
    let json = r#"{
        "s_integrity": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "last_prime_move": 3,
        "policy_root_hash": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        "crmf_certificate": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
        "lambda_m_resonance_score": 0.87
    }"#;
    let receipt: PwehReceipt = serde_json::from_str(json).unwrap();
    assert!(validate_receipt(&receipt));
}

#[test]
fn test_invalid_hash_length() {
    let json = r#"{
        "s_integrity": "short",
        "last_prime_move": 3,
        "policy_root_hash": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        "crmf_certificate": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
        "lambda_m_resonance_score": 0.5
    }"#;
    let receipt: PwehReceipt = serde_json::from_str(json).unwrap();
    assert!(!validate_receipt(&receipt));
}

#[test]
fn test_invalid_resonance_out_of_range() {
    let json = r#"{
        "s_integrity": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "last_prime_move": 3,
        "policy_root_hash": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        "crmf_certificate": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
        "lambda_m_resonance_score": 1.5
    }"#;
    let receipt: PwehReceipt = serde_json::from_str(json).unwrap();
    assert!(!validate_receipt(&receipt));
}
