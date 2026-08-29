use ratchet::phase_e_public_audit::PublicAuditSuite;
use ratchet::receipt::{CeilingRecord, ReceiptRecord};

#[test]
fn test_public_audit_bundle_generation_and_offline_verification() {
    let receipt = ReceiptRecord {
        burst_id: 1,
        snapshot_id: 10,
        t_pred_used: 2.5,
        lambda_hat_final: 0.15,
        v_score_final: 0.95,
        c3_pass: true,
        post_use_pass: true,
        state_hash: "hash_deadbeef_001".to_string(),
        c_ext_signature: "SIG_CEXT_LOCKED_01".to_string(),
        issue_time: 100,
        expiry_time: 1000,
    };

    let ceiling = CeilingRecord {
        max_coordinates: 256,
        max_lambda_hat: 2.5,
        max_theta_norm: 100.0,
        max_v_change_per_burst: 0.5,
        max_bursts_unreviewed: 100,
    };

    let bundle = PublicAuditSuite::generate_bundle(
        vec![receipt],
        ceiling,
        true, // formal proofs passed
        true, // red team battery passed
        150,  // current timestamp
    );

    // Offline third-party validation
    let is_valid = PublicAuditSuite::verify_bundle_offline(&bundle, 200);
    assert!(is_valid, "Public audit bundle failed offline verification");

    // Tampered digest check
    let mut tampered = bundle.clone();
    tampered.bundle_digest = "tampered_digest_corrupted".to_string();
    assert!(!PublicAuditSuite::verify_bundle_offline(&tampered, 200));

    // Expired receipt check
    assert!(!PublicAuditSuite::verify_bundle_offline(&bundle, 2000));
}
