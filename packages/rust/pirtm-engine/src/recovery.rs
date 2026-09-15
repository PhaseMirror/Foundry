//! Phase D: dual-signature recovery sequence and the 9-step ACE resumption
//! gate (ADR-0066 §"Phase D Recovery Sequence" / §"The ACE Verification Gate").
//!
//! After an L0 epoch kill, the frontier halts (`L0_HALT`). Phase D releases the
//! halt through a **gap payload** sealed by the Poseidon2 sponge
//! (`crmf_validity_seal`), bridged to two independently-held Ed25519 signer
//! keys. The gate is fail-closed across nine steps; step `n` of
//! [`verify_resumption_request`] corresponds to condition `n` of the ADR's ACE
//! verification gate:
//!
//! | Gate step | Check | Failure |
//! | --- | --- | --- |
//! | 1 | Gap payload seals to the requested `crmf_validity_seal` | `SealMismatch` |
//! | 2 | Absolute ACE-epoch monotonicity (`ace_epoch > last_committed`) | `EpochRegression` |
//! | 3 | Lost-window is well ordered (`start < end`) | `WindowReversal` |
//! | 4 | Lost-window span is within the tolerated gap | `GapOverflow` |
//! | 5 | A halt certificate (`kill_cert_hash`) is cited | `KillCertificateMissing` |
//! | 6 | Chain continuity: `predecessor_hash == last_committed_root` | `PredecessorMismatch` |
//! | 7 | UOR identity of the requester matches the manifold | `IdentityMismatch` |
//! | 8 | Dual authorization: both registered verifier keys sign the bridge | `SignatureInvalid` |
//! | 9 | Anti-self-dealing: the two authorizing slots are distinct keys | `SelfDealing` |
//!
//! Every branch is a plain equality/comparison, so the gate is deterministic
//! and auditable byte-for-byte.

use ed25519_dalek::{Signature, Signer, SigningKey, VerifyingKey};
use serde::{Deserialize, Serialize};

use crate::poseidon2::Poseidon2Sponge;

/// The `GapPayload` of the Phoenix window: the semantic payload loss region a
/// recovered session resumes from.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct GapPayload {
    /// Hash of the last L0-halted committed state (`chain continuity`).
    pub predecessor_hash: [u8; 32],
    /// Hash of the halting `SIG_GOV_KILL` certificate.
    pub kill_cert_hash: [u8; 32],
    /// Fresh nonce isolating the resumed session from replay of the killed one.
    pub new_session_nonce: [u8; 32],
    /// Absolute ACE epoch.
    pub ace_epoch: u64,
    /// Protocol version of the recovery bridge.
    pub protocol_version: u16,
    /// First lost frame (inclusive).
    pub lost_window_start: u64,
    /// Last lost frame (exclusive).
    pub lost_window_end: u64,
}

impl GapPayload {
    /// Canonical BCS bytes of the gap payload.
    #[must_use]
    pub fn to_canonical_bytes(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(32 + 32 + 32 + 8 + 2 + 8 + 8);
        out.extend_from_slice(&self.predecessor_hash);
        out.extend_from_slice(&self.kill_cert_hash);
        out.extend_from_slice(&self.new_session_nonce);
        out.extend_from_slice(&self.ace_epoch.to_be_bytes());
        out.extend_from_slice(&self.protocol_version.to_be_bytes());
        out.extend_from_slice(&self.lost_window_start.to_be_bytes());
        out.extend_from_slice(&self.lost_window_end.to_be_bytes());
        out
    }

    /// The `crmf_validity_seal` committing to this gap payload.
    #[must_use]
    pub fn seal(&self) -> [u8; 32] {
        Poseidon2Sponge::seal(&self.to_canonical_bytes())
    }
}

/// Protocol failure discriminants, aligned 1:1 with the gate steps above.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, thiserror::Error)]
pub enum RecoveryError {
    #[error("gate step 1: gap payload does not seal to the request seal")]
    SealMismatch,
    #[error("gate step 2: ACE epoch regression (not strictly monotonic)")]
    EpochRegression,
    #[error("gate step 3: lost window is reversed (start >= end)")]
    WindowReversal,
    #[error("gate step 4: lost window span exceeds the tolerated gap")]
    GapOverflow,
    #[error("gate step 5: no halt certificate (kill_cert_hash) cited")]
    KillCertificateMissing,
    #[error("gate step 6: predecessor hash breaks chain continuity")]
    PredecessorMismatch,
    #[error("gate step 7: UOR identity does not match the manifold")]
    IdentityMismatch,
    #[error("gate step 8: dual authorization failed — signature does not verify")]
    SignatureInvalid,
    #[error("gate step 9: anti-self-dealing — signer slots are not distinct keys")]
    SelfDealing,
}

/// Node-side state the gate judges the request against.
#[derive(Debug, Clone)]
pub struct RecoveryContext {
    /// The manifold's UOR identity.
    pub uor_identity: [u8; 32],
    /// Last committed frontier root before the halt.
    pub last_committed_root: [u8; 32],
    /// Last committed ACE epoch.
    pub last_committed_epoch: u64,
    /// Maximum tolerable recovery window.
    pub tolerated_gap: u64,
    /// The two registered enterprise verifier keys (`dual-authorization`).
    pub verifiers: [VerifyingKey; 2],
}

/// A surrounded, dual-authorized resumption request.
#[derive(Debug, Clone)]
pub struct ResumptionRequest {
    /// The gap payload being bridged.
    pub gap: GapPayload,
    /// `crmf_validity_seal` binding the payload (step 1).
    pub seal: [u8; 32],
    /// The two Ed25519 signatures over the bridged seal bytes.
    pub signatures: [Signature; 2],
    /// Which verifier slot produced each signature (`0`/`1`), anti-self-dealing.
    pub signer_slots: [u8; 2],
    /// UOR identity of the requesting endpoint (step 7).
    pub requester_identity: [u8; 32],
}

/// Successful resumption datum: the epoch resumes at and the recovered root.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RecoveryOutcome {
    /// The ACE epoch the resumption lands on.
    pub resumed_epoch: u64,
    /// The recovered frontier root.
    pub new_root: [u8; 32],
}

/// Bytes signed by both enterprise signers (the *bridge*).
#[must_use]
pub fn signable_bridge(seal: &[u8; 32], gap: &GapPayload) -> Vec<u8> {
    let mut msg = Vec::with_capacity(32 + 2 + 8);
    msg.extend_from_slice(seal);
    msg.extend_from_slice(&gap.protocol_version.to_be_bytes());
    msg.extend_from_slice(&gap.ace_epoch.to_be_bytes());
    msg
}

/// Fail-closed 9-step ACE resumption gate.
pub fn verify_resumption_request(
    ctx: &RecoveryContext,
    req: &ResumptionRequest,
) -> Result<RecoveryOutcome, RecoveryError> {
    // 1. Seal binding.
    if req.seal != req.gap.seal() {
        return Err(RecoveryError::SealMismatch);
    }
    // 2. Absolute epoch monotonicity.
    if req.gap.ace_epoch <= ctx.last_committed_epoch {
        return Err(RecoveryError::EpochRegression);
    }
    // 3. Window ordering.
    if req.gap.lost_window_end <= req.gap.lost_window_start {
        return Err(RecoveryError::WindowReversal);
    }
    // 4. Window span bounded.
    if req.gap.lost_window_end - req.gap.lost_window_start > ctx.tolerated_gap {
        return Err(RecoveryError::GapOverflow);
    }
    // 5. Halt certificate cited.
    if req.gap.kill_cert_hash == [0u8; 32] {
        return Err(RecoveryError::KillCertificateMissing);
    }
    // 6. Chain continuity.
    if req.gap.predecessor_hash != ctx.last_committed_root {
        return Err(RecoveryError::PredecessorMismatch);
    }
    // 7. UOR identity.
    if req.requester_identity != ctx.uor_identity {
        return Err(RecoveryError::IdentityMismatch);
    }
    // 8. Dual authorization on the signable bridge.
    let bridge = signable_bridge(&req.seal, &req.gap);
    for (slot, sig) in req.signer_slots.iter().zip(&req.signatures) {
        let key = match *slot {
            0 => &ctx.verifiers[0],
            1 => &ctx.verifiers[1],
            _ => return Err(RecoveryError::SignatureInvalid),
        };
        if key.verify_strict(&bridge, sig).is_err() {
            return Err(RecoveryError::SignatureInvalid);
        }
    }
    // 9. Anti-self-dealing: the two slots must be the two distinct keys.
    if req.signer_slots[0] == req.signer_slots[1] {
        return Err(RecoveryError::SelfDealing);
    }

    // Recovery: deterministic reconstruction of the new frontier root.
    let mut root_input = Vec::with_capacity(32 + 32 + 32);
    root_input.extend_from_slice(&req.gap.predecessor_hash);
    root_input.extend_from_slice(&req.gap.kill_cert_hash);
    root_input.extend_from_slice(&req.gap.new_session_nonce);
    let new_root = crate::canonical::sha256_canonical(&root_input);

    Ok(RecoveryOutcome {
        resumed_epoch: req.gap.ace_epoch,
        new_root,
    })
}

/// Convenience: derive the two enterprise signer keys from two fixed seeds and
/// quote a request. Deterministic for testing and reproducible audits.
pub fn sign_resumption_request(
    gap: GapPayload,
    signer_keys: [&SigningKey; 2],
    signer_slots: [u8; 2],
    requester_identity: [u8; 32],
) -> ResumptionRequest {
    let seal = gap.seal();
    let bridge = signable_bridge(&seal, &gap);
    let signatures = [
        signer_keys[0].sign(&bridge),
        signer_keys[1].sign(&bridge),
    ];
    ResumptionRequest {
        gap,
        seal,
        signatures,
        signer_slots,
        requester_identity,
    }
}

/// Deserialization helper for audits: a signature's raw 64 bytes.
#[must_use]
pub fn signature_bytes(sig: &Signature) -> [u8; 64] {
    sig.to_bytes()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ctx() -> RecoveryContext {
let (vk0, _) = seed0();
        let (vk1, _) = seed1();
        RecoveryContext {
            uor_identity: [0x11; 32],
            last_committed_root: [0x22; 32],
            last_committed_epoch: 41,
            tolerated_gap: 64,
            verifiers: [vk0, vk1],
        }
    }

    fn seed0() -> (VerifyingKey, SigningKey) {
        let sk = SigningKey::from_bytes(&[0x01; 32]);
        (sk.verifying_key(), sk)
    }

    fn seed1() -> (VerifyingKey, SigningKey) {
        let sk = SigningKey::from_bytes(&[0x02; 32]);
        (sk.verifying_key(), sk)
    }

    /// Wire the full positive lifecycle: kill → gap → resumption → L0_HALT
    /// release.
    #[test]
    fn phase_d_positive_recovery() {
        let ctx = ctx();
        let (_, sk0) = seed0();
        let (_, sk1) = seed1();
        let gap = GapPayload {
            predecessor_hash: [0x22; 32],
            kill_cert_hash: [0xaa; 32], // cited kill certificate
            new_session_nonce: [0xbb; 32],
            ace_epoch: 42,
            protocol_version: 0x0001,
            lost_window_start: 87,
            lost_window_end: 121,
        };
        let req = sign_resumption_request(
            gap,
            [&sk0, &sk1],
            [0, 1],
            ctx.uor_identity,
        );
        let outcome = verify_resumption_request(&ctx, &req).expect("gate passes");
        assert!(outcome.resumed_epoch > ctx.last_committed_epoch);
    }

    #[test]
    fn gate_step1_seal_tampering() {
        let ctx = ctx();
        let (_, sk0) = seed0();
        let (_, sk1) = seed1();
        let mut req = sign_resumption_request(
            ctx_gap(),
            [&sk0, &sk1],
            [0, 1],
            ctx.uor_identity,
        );
        req.seal[0] ^= 0x01;
        assert_eq!(
            verify_resumption_request(&ctx, &req),
            Err(RecoveryError::SealMismatch)
        );
    }

    #[test]
    fn gate_step2_epoch_regression() {
        let ctx = ctx();
        let (_, sk0) = seed0();
        let (_, sk1) = seed1();
        let mut gap = ctx_gap();
        gap.ace_epoch = ctx.last_committed_epoch; // not strictly greater
        let req = sign_resumption_request(gap, [&sk0, &sk1], [0, 1], ctx.uor_identity);
        assert_eq!(
            verify_resumption_request(&ctx, &req),
            Err(RecoveryError::EpochRegression)
        );
    }

    #[test]
    fn gate_step3_window_reversal() {
        let ctx = ctx();
        let (_, sk0) = seed0();
        let (_, sk1) = seed1();
        let mut gap = ctx_gap();
        gap.lost_window_end = gap.lost_window_start; // empty window
        let req = sign_resumption_request(gap, [&sk0, &sk1], [0, 1], ctx.uor_identity);
        assert_eq!(
            verify_resumption_request(&ctx, &req),
            Err(RecoveryError::WindowReversal)
        );
    }

    #[test]
    fn gate_step4_gap_overflow() {
        let ctx = ctx();
        let (_, sk0) = seed0();
        let (_, sk1) = seed1();
        let mut gap = ctx_gap();
        gap.lost_window_end = gap.lost_window_start + ctx.tolerated_gap + 1;
        let req = sign_resumption_request(gap, [&sk0, &sk1], [0, 1], ctx.uor_identity);
        assert_eq!(
            verify_resumption_request(&ctx, &req),
            Err(RecoveryError::GapOverflow)
        );
    }

    #[test]
    fn gate_step5_missing_kill_certificate() {
        let ctx = ctx();
        let (_, sk0) = seed0();
        let (_, sk1) = seed1();
        let mut gap = ctx_gap();
        gap.kill_cert_hash = [0u8; 32];
        let req = sign_resumption_request(gap, [&sk0, &sk1], [0, 1], ctx.uor_identity);
        assert_eq!(
            verify_resumption_request(&ctx, &req),
            Err(RecoveryError::KillCertificateMissing)
        );
    }

    #[test]
    fn gate_step6_chain_continuity() {
        let ctx = ctx();
        let (_, sk0) = seed0();
        let (_, sk1) = seed1();
        let mut gap = ctx_gap();
        gap.predecessor_hash = [0x99; 32];
        let req = sign_resumption_request(gap, [&sk0, &sk1], [0, 1], ctx.uor_identity);
        assert_eq!(
            verify_resumption_request(&ctx, &req),
            Err(RecoveryError::PredecessorMismatch)
        );
    }

    #[test]
    fn gate_step7_identity_mismatch() {
        let ctx = ctx();
        let (_, sk0) = seed0();
        let (_, sk1) = seed1();
        let req = sign_resumption_request(ctx_gap(), [&sk0, &sk1], [0, 1], [0xff; 32]);
        assert_eq!(
            verify_resumption_request(&ctx, &req),
            Err(RecoveryError::IdentityMismatch)
        );
    }

    #[test]
    fn gate_step8_rogue_signature() {
        let ctx = ctx();
        let (_, sk0) = seed0();
        let (_, sk1) = seed1();
        // Sign slot 0 with a third, unregistered key.
        let rogue = SigningKey::from_bytes(&[0x03; 32]);
        let seal = ctx_gap().seal();
        let bridge = signable_bridge(&seal, &ctx_gap());
        let mut req = sign_resumption_request(ctx_gap(), [&sk0, &sk1], [0, 1], ctx.uor_identity);
        req.signatures[0] = rogue.sign(&bridge);
        assert_eq!(
            verify_resumption_request(&ctx, &req),
            Err(RecoveryError::SignatureInvalid)
        );
    }

    #[test]
    fn gate_step9_self_dealing() {
        let ctx = ctx();
        let (_, sk0) = seed0();
        let _ = seed1();
        // Both slots point at the same key: a single signer masquerading.
        let req = sign_resumption_request(ctx_gap(), [&sk0, &sk0], [0, 0], ctx.uor_identity);
        assert_eq!(
            verify_resumption_request(&ctx, &req),
            Err(RecoveryError::SelfDealing)
        );
    }

    fn ctx_gap() -> GapPayload {
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

    #[test]
    fn gap_seal_is_deterministic() {
        let gap = ctx_gap();
        assert_eq!(gap.seal(), gap.seal());
        assert_eq!(gap.seal(), Poseidon2Sponge::seal(&gap.to_canonical_bytes()));
    }
}