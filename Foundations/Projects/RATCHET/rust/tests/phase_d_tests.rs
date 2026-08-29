use ratchet::phase_d_governance_halt::{
    GovernanceHaltInterlock, GovernanceReleaseToken, HaltReason,
};

#[test]
fn test_governance_halt_multi_sig_release_flow() {
    let authorized = vec![
        "auditor_alice".to_string(),
        "safety_lead_bob".to_string(),
        "constitutional_carol".to_string(),
    ];
    let mut interlock = GovernanceHaltInterlock::new(2, authorized);

    // Record emergency halt
    interlock.record_halt(
        1,
        100,
        HaltReason::SandboxBreach {
            detail: "Unwhitelisted code execution attempted".to_string(),
        },
        42,
        "state_hash_abc_123".to_string(),
    );
    assert_eq!(interlock.audit_log.len(), 1);

    // 1. Attempt release with only 1 signature (insufficient)
    let token_1_sig = GovernanceReleaseToken {
        burst_id: 1,
        target_snapshot_id: 42,
        nonce: 1001,
        approver_signatures: vec![("auditor_alice".to_string(), "SIG_ALICE".to_string())],
        expiry_timestamp: 200,
    };
    assert!(interlock.verify_release_token(&token_1_sig, 105).is_err());

    // 2. Valid multi-sig with 2 authorized approvers
    let token_valid = GovernanceReleaseToken {
        burst_id: 1,
        target_snapshot_id: 42,
        nonce: 1002,
        approver_signatures: vec![
            ("auditor_alice".to_string(), "SIG_ALICE".to_string()),
            ("safety_lead_bob".to_string(), "SIG_BOB".to_string()),
        ],
        expiry_timestamp: 200,
    };
    let restored_snap = interlock.verify_release_token(&token_valid, 105);
    assert_eq!(restored_snap, Ok(42));

    // 3. Replay attack attempt with same nonce
    let replay_attempt = interlock.verify_release_token(&token_valid, 106);
    assert!(replay_attempt.is_err(), "Nonce replay attack was not blocked");

    // 4. Expired token attempt
    let token_expired = GovernanceReleaseToken {
        burst_id: 1,
        target_snapshot_id: 42,
        nonce: 1003,
        approver_signatures: vec![
            ("auditor_alice".to_string(), "SIG_ALICE".to_string()),
            ("safety_lead_bob".to_string(), "SIG_BOB".to_string()),
        ],
        expiry_timestamp: 50,
    };
    assert!(interlock.verify_release_token(&token_expired, 105).is_err());
}
