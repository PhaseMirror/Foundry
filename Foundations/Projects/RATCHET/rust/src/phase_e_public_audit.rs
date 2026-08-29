//! Phase E: Public Cryptographic Audit Harness and Verifiable Bundle Generator (ADR-0039 §12)

use crate::receipt::{CeilingRecord, ReceiptRecord};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

/// Public verification bundle allowing third parties to audit safety receipts offline.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PublicAuditBundle {
    pub project_name: String,
    pub spec_version: String,
    pub timestamp: u64,
    pub issued_receipts: Vec<ReceiptRecord>,
    pub ceiling_record: CeilingRecord,
    pub formal_proofs_passed: bool,
    pub red_team_battery_passed: bool,
    pub bundle_digest: String,
}

/// Public audit generator and offline verification engine.
pub struct PublicAuditSuite;

impl PublicAuditSuite {
    /// Compute cryptographic digest over the full audit package.
    pub fn compute_bundle_digest(
        receipts: &[ReceiptRecord],
        ceiling: &CeilingRecord,
        proofs_ok: bool,
        red_team_ok: bool,
    ) -> String {
        let mut hasher = Sha256::new();
        hasher.update(b"RATCHET_PUBLIC_AUDIT_V4.2");
        hasher.update(receipts.len().to_le_bytes());
        for r in receipts {
            hasher.update(r.state_hash.as_bytes());
            hasher.update(r.c_ext_signature.as_bytes());
        }
        hasher.update(ceiling.max_coordinates.to_le_bytes());
        hasher.update(if proofs_ok { &[1u8] } else { &[0u8] });
        hasher.update(if red_team_ok { &[1u8] } else { &[0u8] });
        hex::encode(hasher.finalize())
    }

    /// Assemble a complete public audit bundle.
    pub fn generate_bundle(
        receipts: Vec<ReceiptRecord>,
        ceiling: CeilingRecord,
        proofs_ok: bool,
        red_team_ok: bool,
        current_time: u64,
    ) -> PublicAuditBundle {
        let bundle_digest = Self::compute_bundle_digest(&receipts, &ceiling, proofs_ok, red_team_ok);
        PublicAuditBundle {
            project_name: "Project RATCHET".to_string(),
            spec_version: "ADR-0039 v4.2".to_string(),
            timestamp: current_time,
            issued_receipts: receipts,
            ceiling_record: ceiling,
            formal_proofs_passed: proofs_ok,
            red_team_battery_passed: red_team_ok,
            bundle_digest,
        }
    }

    /// Independent offline verification of a public audit bundle.
    pub fn verify_bundle_offline(bundle: &PublicAuditBundle, current_time: u64) -> bool {
        // 1. Verify bundle digest integrity
        let expected_digest = Self::compute_bundle_digest(
            &bundle.issued_receipts,
            &bundle.ceiling_record,
            bundle.formal_proofs_passed,
            bundle.red_team_battery_passed,
        );
        if bundle.bundle_digest != expected_digest {
            return false;
        }

        // 2. Check formal methods and red-team certifications
        if !bundle.formal_proofs_passed || !bundle.red_team_battery_passed {
            return false;
        }

        // 3. Check that all included receipts are unexpired and structurally valid
        for receipt in &bundle.issued_receipts {
            if !receipt.is_valid(current_time) {
                return false;
            }
        }

        true
    }
}
