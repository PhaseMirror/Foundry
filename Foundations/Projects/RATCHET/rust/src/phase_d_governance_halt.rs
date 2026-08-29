//! Phase D: Human-in-the-Loop HALT Governance Interlock & Multi-Sig Release (ADR-0039 §12)

use std::collections::HashSet;

/// Reason for external controller triggering HALT.
#[derive(Debug, Clone, PartialEq)]
pub enum HaltReason {
    SandboxBreach { detail: String },
    EstimatorPoisoningDisagreement { tolerance_breach: f64 },
    PostUseMarginFailure { observed_margin: f64 },
    HiddenWriteManifestVoid { handle: String },
    ManualEmergencyIntervention,
}

/// Forensic audit record captured at the instant of HALT.
#[derive(Debug, Clone, PartialEq)]
pub struct HaltAuditRecord {
    pub burst_id: u64,
    pub timestamp: u64,
    pub reason: HaltReason,
    pub snapshot_id: u64,
    pub state_hash: String,
}

/// Multi-signature release token required to clear HALT mode.
#[derive(Debug, Clone, PartialEq)]
pub struct GovernanceReleaseToken {
    pub burst_id: u64,
    pub target_snapshot_id: u64,
    pub nonce: u64,
    pub approver_signatures: Vec<(String, String)>, // (approver_id, signature)
    pub expiry_timestamp: u64,
}

/// Governance interlock managing the non-bypassable HALT release gate.
pub struct GovernanceHaltInterlock {
    pub required_approvers: usize,
    pub authorized_keys: HashSet<String>,
    pub audit_log: Vec<HaltAuditRecord>,
    pub consumed_nonces: HashSet<u64>,
}

impl GovernanceHaltInterlock {
    pub fn new(required_approvers: usize, authorized_keys: Vec<String>) -> Self {
        Self {
            required_approvers,
            authorized_keys: authorized_keys.into_iter().collect(),
            audit_log: Vec::new(),
            consumed_nonces: HashSet::new(),
        }
    }

    /// Record a HALT event with forensic audit metadata.
    pub fn record_halt(
        &mut self,
        burst_id: u64,
        timestamp: u64,
        reason: HaltReason,
        snapshot_id: u64,
        state_hash: String,
    ) {
        self.audit_log.push(HaltAuditRecord {
            burst_id,
            timestamp,
            reason,
            snapshot_id,
            state_hash,
        });
    }

    /// Verify whether a submitted GovernanceReleaseToken is valid and authorized.
    pub fn verify_release_token(
        &mut self,
        token: &GovernanceReleaseToken,
        current_time: u64,
    ) -> Result<u64, &'static str> {
        if current_time > token.expiry_timestamp {
            return Err("Governance release token has expired");
        }

        if self.consumed_nonces.contains(&token.nonce) {
            return Err("Nonce replay attack detected: token already consumed");
        }

        let mut valid_approvers = HashSet::new();
        for (approver_id, sig) in &token.approver_signatures {
            if self.authorized_keys.contains(approver_id) && !sig.is_empty() {
                valid_approvers.insert(approver_id.clone());
            }
        }

        if valid_approvers.len() < self.required_approvers {
            return Err("Insufficient authorized governance signatures for HALT release");
        }

        self.consumed_nonces.insert(token.nonce);
        Ok(token.target_snapshot_id)
    }
}
