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
