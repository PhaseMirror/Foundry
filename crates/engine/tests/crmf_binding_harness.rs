// crates/engine/tests/crmf_binding_harness.rs
//! Integration tests for the telemetry frame and lawful recursion hash.

use engine::{FPGATelemetryFrame, SecurityState, compute_lawful_recursion_hash};

#[test]
fn test_deterministic_serialization() {
    let frame = FPGATelemetryFrame::new(0xABCD1234, 1_600_000_000, 0xFF);
    let bytes = frame.to_canonical_bytes();
    // BCS serialization is deterministic – compare against a second call.
    let bytes2 = frame.to_canonical_bytes();
    assert_eq!(bytes, bytes2);
    assert!(!bytes.is_empty(), "Serialized payload must not be empty");
}

#[test]
fn test_hash_consistency() {
    let prev = [0u8; 32];
    let frame = FPGATelemetryFrame::new(0, 0, 0);
    let state = SecurityState::new(0);
    let h1 = compute_lawful_recursion_hash(&prev, &frame, &state);
    let h2 = compute_lawful_recursion_hash(&prev, &frame, &state);
    assert_eq!(h1, h2, "Hash must be deterministic for identical inputs");
    assert_eq!(h1.len(), 32);
}

#[test]
fn test_hash_varies_on_input() {
    let prev = [0u8; 32];
    let frame1 = FPGATelemetryFrame::new(1, 1, 0);
    let frame2 = FPGATelemetryFrame::new(2, 1, 0);
    let state = SecurityState::new(0);
    let h1 = compute_lawful_recursion_hash(&prev, &frame1, &state);
    let h2 = compute_lawful_recursion_hash(&prev, &frame2, &state);
    assert_ne!(h1, h2, "Changing telemetry must change the hash");
}

