//! Integration tests mirroring `test_pweh_adapter.py`, plus end-to-end CLI
//! runs against the checked-in `checkpoints/*.json` fixtures.

use pweh_parser::{DecisionAssureAdapter, PwehReceipt};
use std::path::Path;
use std::process::Command;

fn adapter() -> DecisionAssureAdapter {
    DecisionAssureAdapter
}

fn parse(json: &str) -> PwehReceipt {
    serde_json::from_str(json).unwrap()
}

/// The exact valid checkpoint from `test_pweh_adapter.py`.
const VALID_JSON: &str = r#"{
    "s_integrity": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
    "last_prime_move": 43,
    "policy_root_hash": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
    "crmf_certificate": "1111111111111111111111111111111111111111111111111111111111111111",
    "lambda_m_resonance_score": 0.992
}"#;

#[test]
fn known_good_checkpoint_passes() {
    let result = adapter().verify_checkpoint(&parse(VALID_JSON));
    assert_eq!(result.continuity_result, "PASS");
    assert!(result.is_pass());
    assert!(result.violation_details.is_empty());
}

#[test]
fn invalid_hash_length_is_rejected() {
    // Mirror of test_invalid_hash_length: a too-short `s_integrity` plus
    // over-long policy/crmf hashes.
    let json = r#"{
        "s_integrity": "short",
        "last_prime_move": 3,
        "policy_root_hash": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
        "crmf_certificate": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
    }"#;
    let result = adapter().verify_checkpoint(&parse(json));
    assert_eq!(result.continuity_result, "FAIL");
    assert!(!result.is_pass());
    assert!(result
        .violation_details
        .iter()
        .any(|e| e.contains("length is")));
}

#[test]
fn resonance_score_out_of_bounds_is_rejected() {
    let json = r#"{
        "s_integrity": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "last_prime_move": 3,
        "policy_root_hash": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        "crmf_certificate": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
        "lambda_m_resonance_score": 1.5
    }"#;
    let result = adapter().verify_checkpoint(&parse(json));
    assert_eq!(result.continuity_result, "FAIL");
    assert!(result
        .violation_details
        .iter()
        .any(|e| e.contains("between 0.0 and 1.0")));
}

#[test]
fn uppercase_or_prefixed_hashes_are_rejected() {
    // Mirror of test_invalid_hash_characters: `0x` prefix and uppercase hex.
    let json = r#"{
        "s_integrity": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab",
        "last_prime_move": 43,
        "policy_root_hash": "ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890",
        "crmf_certificate": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
        "lambda_m_resonance_score": 0.5
    }"#;
    let result = adapter().verify_checkpoint(&parse(json));
    assert_eq!(result.continuity_result, "FAIL");
    assert!(result
        .violation_details
        .iter()
        .any(|e| e.contains("invalid characters")));
}

#[test]
fn non_prime_last_move_is_rejected() {
    // Mirror of test_prime_validation: `last_prime_move = 4` is composite.
    let json = r#"{
        "s_integrity": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "last_prime_move": 4,
        "policy_root_hash": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        "crmf_certificate": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
        "lambda_m_resonance_score": 0.5
    }"#;
    let result = adapter().verify_checkpoint(&parse(json));
    assert_eq!(result.continuity_result, "FAIL");
    assert!(result.violation_details.iter().any(|e| e.contains("prime")));
}

#[test]
fn missing_fields_default_like_python_get() {
    let receipt: PwehReceipt = serde_json::from_str("{}").unwrap();
    let result = adapter().verify_checkpoint(&receipt);
    assert_eq!(result.continuity_result, "FAIL");
    assert_eq!(result.receipt_hash, "");
    // s_integrity is empty, policy/crmf hashes are empty, prime 0 is not
    // prime, resonance 0.0 is in-bounds -> exactly 5 distinct checks with
    // 4 failures.
    assert_eq!(result.violation_details.len(), 4);
}

fn fixture_path(name: &str) -> String {
    let dir = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("checkpoints")
        .join(name);
    dir.to_string_lossy().into_owned()
}

fn run_cli(path: &str) -> (i32, String) {
    let output = Command::new(env!("CARGO_BIN_EXE_verify-checkpoint"))
        .arg(path)
        .output()
        .expect("spawn verify-checkpoint");
    (
        output.status.code().expect("exit code"),
        String::from_utf8(output.stdout).expect("utf-8 stdout"),
    )
}

#[test]
fn cli_valid_checkpoint_exits_zero() {
    let (code, stdout) = run_cli(&fixture_path("valid_checkpoint.json"));
    assert_eq!(code, 0);
    let parsed: serde_json::Value = serde_json::from_str(&stdout).unwrap();
    assert_eq!(parsed["continuity_result"], "PASS");
    assert_eq!(
        parsed["receipt_hash"],
        "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    );
}

#[test]
fn cli_invalid_checkpoint_exits_one() {
    for name in [
        "invalid_hash_length.json",
        "invalid_hash_format.json",
        "invalid_resonance.json",
    ] {
        let (code, stdout) = run_cli(&fixture_path(name));
        assert_eq!(code, 1, "fixture {name} should exit 1");
        let parsed: serde_json::Value = serde_json::from_str(&stdout).unwrap();
        assert_eq!(parsed["continuity_result"], "FAIL");
        assert!(!parsed["violation_details"].as_array().unwrap().is_empty());
    }
}

#[test]
fn cli_parse_error_exits_one() {
    let dir = tempfile::tempdir().unwrap();
    let bad = dir.path().join("not_json.json");
    std::fs::write(&bad, "{ not valid json").unwrap();
    let output = Command::new(env!("CARGO_BIN_EXE_verify-checkpoint"))
        .arg(bad.to_string_lossy().into_owned())
        .output()
        .expect("spawn verify-checkpoint");
    assert_eq!(output.status.code(), Some(1));
}

#[test]
fn cli_missing_argument_prints_usage_and_exits_one() {
    let output = Command::new(env!("CARGO_BIN_EXE_verify-checkpoint"))
        .output()
        .expect("spawn verify-checkpoint");
    assert_eq!(output.status.code(), Some(1));
    assert!(!output.stderr.is_empty());
}
