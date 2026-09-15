//! Phase D end-to-end integration (ADR-0066 §"Phase D Recovery Sequence"):
//! after an L0 kill, the frontier `L0_HALT`s; a gap payload is sealed,
//! dual-signed by two enterprise signers, and the 9-step ACE gate releases the
//! halt with a deterministic recovered root.

use ed25519_dalek::{SigningKey, VerifyingKey};
use pirtm_engine::recovery::{
    GapPayload, RecoveryContext, RecoveryError, ResumptionRequest, sign_resumption_request,
    signable_bridge, verify_resumption_request,
};

fn signer(i: u8) -> (VerifyingKey, SigningKey) {
    let sk = SigningKey::from_bytes(&[i; 32]);
    (sk.verifying_key(), sk)
}

fn sample_gap() -> GapPayload {
    GapPayload {
        predecessor_hash: [0x22; 32],
        kill_cert_hash: [0xaa; 32],
        new_session_nonce: [0xbb; 32],
        ace_epoch: 42,
        protocol_version: 0x0001,
        lost_window_start: 87,
        lost_window_end: 121,
    }
}

fn context() -> RecoveryContext {
    let (vk0, _) = signer(1);
    let (vk1, _) = signer(2);
    RecoveryContext {
        uor_identity: [0x11; 32],
        last_committed_root: [0x22; 32],
        last_committed_epoch: 41,
        tolerated_gap: 64,
        verifiers: [vk0, vk1],
    }
}

fn request(ctx: &RecoveryContext) -> ResumptionRequest {
    let (_, sk0) = signer(1);
    let (_, sk1) = signer(2);
    sign_resumption_request(sample_gap(), [&sk0, &sk1], [0, 1], ctx.uor_identity)
}

#[test]
fn dual_authorized_recovery_releases_the_halt() {
    let ctx = context();
    let req = request(&ctx);
    let outcome = verify_resumption_request(&ctx, &req).expect("gate releases L0_HALT");
    assert!(outcome.resumed_epoch > ctx.last_committed_epoch);
    // Deterministic new root reconstruction.
    let mut root_input = Vec::with_capacity(96);
    root_input.extend_from_slice(&req.gap.predecessor_hash);
    root_input.extend_from_slice(&req.gap.kill_cert_hash);
    root_input.extend_from_slice(&req.gap.new_session_nonce);
    assert_eq!(outcome.new_root, pirtm_engine::canonical::sha256_canonical(&root_input));
}

#[test]
fn recovered_root_distinguishes_sessions_by_nonce() {
    let ctx = context();
    let gap_a = sample_gap();
    let mut gap_b = sample_gap();
    gap_b.new_session_nonce[0] ^= 0x01;
    let (_, sk0) = signer(1);
    let (_, sk1) = signer(2);
    let req_a = sign_resumption_request(gap_a.clone(), [&sk0, &sk1], [0, 1], ctx.uor_identity);
    let req_b = sign_resumption_request(gap_b, [&sk0, &sk1], [0, 1], ctx.uor_identity);
    let a = verify_resumption_request(&ctx, &req_a).expect("a passes");
    let b = verify_resumption_request(&ctx, &req_b).expect("b passes");
    assert_ne!(a.new_root, b.new_root);
}

#[test]
fn bridge_bytes_are_seal_bound_then_epoch_version_then_epoch() {
    let gap = sample_gap();
    let bridge = signable_bridge(&gap.seal(), &gap);
    assert_eq!(&bridge[..32], &gap.seal());
    assert_eq!(&bridge[32..34], &gap.protocol_version.to_be_bytes());
    assert_eq!(&bridge[34..42], &gap.ace_epoch.to_be_bytes());
    assert_eq!(bridge.len(), 42);
}

#[test]
fn gate_rejects_each_failure_discipline_end_to_end() {
    let ctx = context();
    let (_, sk0) = signer(1);
    let (_, sk1) = signer(2);

    let mut original_gap = sample_gap();
    // step 4: gap overflow
    original_gap.lost_window_end = original_gap.lost_window_start + ctx.tolerated_gap + 1;
    let req = sign_resumption_request(original_gap, [&sk0, &sk1], [0, 1], ctx.uor_identity);
    assert_eq!(
        verify_resumption_request(&ctx, &req),
        Err(RecoveryError::GapOverflow)
    );

    // step 6: broken continuity
    let mut original_gap = sample_gap();
    original_gap.predecessor_hash = [0x44; 32];
    let req = sign_resumption_request(original_gap, [&sk0, &sk1], [0, 1], ctx.uor_identity);
    assert_eq!(
        verify_resumption_request(&ctx, &req),
        Err(RecoveryError::PredecessorMismatch)
    );

    // step 9: self-dealing (both slots from the same signer)
    let req = sign_resumption_request(sample_gap(), [&sk0, &sk0], [0, 0], ctx.uor_identity);
    assert_eq!(
        verify_resumption_request(&ctx, &req),
        Err(RecoveryError::SelfDealing)
    );
}