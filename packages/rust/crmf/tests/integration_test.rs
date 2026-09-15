use crmf::*;

#[test]
fn test_poseidon2_commitment_verify() {
    let payload = b"test-poseidon2-payload";
    let commitment = Poseidon2Commitment::new(payload, "test-domain");
    assert!(commitment.verify(payload));
    assert_eq!(commitment.commitment.len(), 32);
}

#[test]
fn test_dual_anchor_sign_and_verify() {
    let keypair = CrmfKeypair::generate();
    let payload = b"test-dual-anchor-payload";

    let anchor = DualAnchor::sign(payload, &keypair);
    anchor.verify(payload).expect("dual anchor verification failed");
}

#[test]
fn test_crmf_seal_roundtrip() {
    let keypair = CrmfKeypair::generate();
    let payload = EnvelopePayload {
        event_type: "test_event".to_string(),
        data: serde_json::json!({"hello": "world"}),
        proof_hashes: vec![],
    };

    let seal = CrmfSeal::new(
        &bcs::serialize(&payload).unwrap(),
        "test-domain",
        &keypair,
    );

    let bcs_payload = bcs::serialize(&payload).unwrap();
    seal.verify(&bcs_payload).expect("seal verification failed");
}

#[test]
fn test_envelope_seal_and_verify() {
    let keypair = CrmfKeypair::generate();
    let payload = EnvelopePayload {
        event_type: "ace_certified_transition".to_string(),
        data: serde_json::json!({"state": "mutation"}),
        proof_hashes: vec![],
    };
    let metadata = EnvelopeMetadata::new("ace-guardian")
        .with_lawful_hash("epoch-001")
        .with_wardmonitor("healthy");

    let envelope = CrmfEnvelope::seal(payload, metadata, "ace-domain", &keypair);
    envelope.verify().expect("envelope verification failed");
}

fn sample_envelope(domain_tag: &str, nonce: u64) -> CrmfEnvelope {
    let keypair = CrmfKeypair::generate();
    let payload = EnvelopePayload {
        event_type: "ace_certified_transition".to_string(),
        data: serde_json::json!({"state": "mutation", "nonce": nonce}),
        proof_hashes: vec![],
    };
    let metadata = EnvelopeMetadata::new("ace-guardian");
    CrmfEnvelope::seal(payload, metadata, domain_tag, &keypair)
}

#[test]
fn test_crmf_ledger_chains_sealed_envelopes() {
    let mut ledger = CrmfLedger::new().with_domain_tag("archivum-domain");
    ledger.append_envelope(&sample_envelope("archivum-domain", 2)).unwrap();
    ledger.append_envelope(&sample_envelope("archivum-domain", 3)).unwrap();
    assert!(ledger.verify_chain(), "chained CRMF envelopes must verify");
    assert!(ledger.archivum.is_linked(), "envelope chain must be hash-linked");
    assert_eq!(ledger.len(), 2);
}

#[test]
fn test_crmf_ledger_rejects_replay_envelope() {
    let mut ledger = CrmfLedger::new().with_domain_tag("archivum-domain");
    let envelope = sample_envelope("archivum-domain", 2);
    ledger.append_envelope(&envelope).unwrap();
    let err = ledger.append_envelope(&envelope).unwrap_err();
    assert!(matches!(err, CrmfError::DuplicateEnvelope { .. }),
        "replayed anchor must be rejected");
}

#[test]
fn test_crmf_ledger_compatible_gate_fails_closed() {
    let mut ledger = CrmfLedger::new().with_domain_tag("archivum-domain");
    let err = ledger.append_envelope(&sample_envelope("crmf-domain", 1)).unwrap_err();
    assert!(matches!(err, CrmfError::DomainTagMismatch { sealed, store }
        if sealed == "crmf-domain" && store == "archivum-domain"),
        "mismatched domain must fail closed");
    assert!(ledger.is_empty(), "nothing may append across a tag mismatch");
}

#[test]
fn test_crmf_ledger_scan_detects_tampering() {
    let mut ledger = CrmfLedger::new().with_domain_tag("archivum-domain");
    ledger.append_envelope(&sample_envelope("archivum-domain", 2)).unwrap();
    assert!(ledger.scan_for_violations().is_empty());

    // Tamper with a chained witness: the re-derivation must report it.
    ledger.archivum.witnesses[0].state_hash.push('X');
    let violations = ledger.scan_for_violations();
    assert!(!violations.is_empty(), "tamper must be detected");
    assert!(
        violations.iter().any(|v| v == "chain integrity violation"),
        "expected a chain integrity violation, got: {violations:?}"
    );
}

#[test]
fn test_crmf_ledger_chain_links_to_prior_anchor() {
    let mut ledger = CrmfLedger::new().with_domain_tag("archivum-domain");
    let e1 = sample_envelope("archivum-domain", 2);
    let e2 = sample_envelope("archivum-domain", 5);
    ledger.append_envelope(&e1).unwrap();
    ledger.append_envelope(&e2).unwrap();
    assert_eq!(
        ledger.archivum.witnesses[1].previous_hash,
        Some(e1.seal.dual_anchor.sha256_hex.clone()),
        "second witness must chain to the first anchor"
    );
    assert_eq!(
        ledger.archivum.witnesses[1].commit_hash,
        Some(e2.seal.bcs_hash.clone()),
        "commit hash binds the witness to the BCS-sealed payload"
    );
}
