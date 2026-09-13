//! End-to-end mirror of `multiplicity/cert/test_ace_crypto_integration.py`.
//!
//! The Python test drives `AceProtocol` (which does not exist in the repo) to
//! certify witnesses; here the witnesses are built directly with the duct-tape
//! `AceCertificate` holder, and the same registry flows are exercised.

use multiplicity_py::cas::{
    get_registry, verify_ace_witness, AceCertificate, AceWitness, CertLevel,
};
use multiplicity_py::crypto::{compute_commitment, verify_commitment, MultiplicityCrypto};

fn witness(prime_index: u64, suffix: &str) -> AceWitness {
    AceWitness::new(
        format!("integration-{suffix}"),
        prime_index,
        "2024-06-01T00:00:00.000000",
        AceCertificate::new(
            CertLevel::new(if prime_index == 2 { 1 } else { 2 }),
            true,
            1.0,
            0.05,
        ),
    )
}

#[test]
fn ace_bridge_stats_are_available() {
    let stats = get_registry().get_witness_stats();
    assert_eq!(stats["crypto_available"], true);
    assert_eq!(stats["crypto_mode"], "fallback");
}

#[test]
fn two_witness_batch_registers_and_verifies() {
    let batch_id = "test-batch-phase2";
    let first = get_registry().register_witness(
        witness(2, "first"),
        Some("test@example.test"),
        Some(batch_id),
    );
    let second = get_registry().register_witness(
        witness(3, "second"),
        Some("reviewer@example.test"),
        Some(batch_id),
    );

    assert!(first.commitment.starts_with("0x"));
    assert!(second.commitment.starts_with("0x"));
    assert_ne!(first.witness.witness_id, second.witness.witness_id);

    assert!(verify_ace_witness(&first.witness.witness_id, None));
    assert!(verify_ace_witness(&second.witness.witness_id, None));

    let batch_root = get_registry()
        .get_batch_root(batch_id)
        .expect("batch root computed");
    assert!(batch_root.starts_with("0x"));

    assert!(verify_ace_witness(
        &first.witness.witness_id,
        Some(&batch_root)
    ));
    assert!(verify_ace_witness(
        &second.witness.witness_id,
        Some(&batch_root)
    ));

    let audit = get_registry().get_audit_trail(None);
    assert!(audit.len() >= 2);
    assert!(audit
        .last()
        .unwrap()
        .get("redacted_identity")
        .and_then(|v| v.as_str())
        .map(|s| s.starts_with("redacted:"))
        .unwrap_or(false));
}

#[test]
fn forced_fallback_mode_is_deterministic() {
    let bridge = MultiplicityCrypto::with_force_fallback(Some(true));
    let status = bridge.get_bridge_status();
    assert_eq!(status.mode, "fallback");

    let commitment = bridge.compute_commitment("fallback-leaf", "fallback-salt");
    assert_eq!(
        commitment,
        compute_commitment("fallback-leaf", "fallback-salt")
    );
    assert!(commitment.starts_with("0x"));
    assert!(verify_commitment(
        &commitment,
        "fallback-leaf",
        "fallback-salt"
    ));

    // Deterministic across bridge instances.
    let second = MultiplicityCrypto::with_force_fallback(Some(true));
    assert_eq!(
        second.compute_commitment("fallback-leaf", "fallback-salt"),
        commitment
    );
}

#[test]
fn matrix_style_certification_flows_through_registry() {
    let crypto_witness = get_registry().register_witness(
        witness(5, "matrix"),
        Some("matrix-test@example.test"),
        Some("matrix-batch-phase2"),
    );
    assert!(crypto_witness.commitment.starts_with("0x"));
    assert!(verify_ace_witness(&crypto_witness.witness.witness_id, None));
}
