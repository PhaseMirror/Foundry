//! CRMF audit-chain integration (non-WORM).
//!
//! `CrmfLedger` retires verified, sealed CRMF envelopes into the chained
//! `ArchivumLedger` rather than appending to a legacy WORM file. Every append:
//!
//! 1. re-verifies the envelope's cryptographic seal (`envelope.verify()`);
//! 2. enforces the `Compatible()` domain-tag gate (ADR-0067) — tag mismatch
//!    fails closed;
//! 3. rejects duplicate anchor hashes (witness uniqueness);
//! 4. links the witness to the preceding anchor (hash chaining).
//!
//! Tamper detection re-runs `verify_chain()` over the chain and re-verifies
//! every stored envelope against its recorded anchor.

use crate::{CrmfEnvelope, CrmfError};
use archivum::{ArchivumError, ArchivumLedger, Witness};

/// CRMF-anchored audit chain bridged to the Λ^p-Archivum.
///
/// The envelope records are retained in memory so that seal re-verification
/// (tamper evidence) is possible; archival persistence of the payload bytes
/// is the job of the content-addressed `LambdaPStore`.
#[derive(Debug, Clone)]
pub struct CrmfLedger {
    pub archivum: ArchivumLedger,
    records: Vec<CrmfEnvelope>,
    domain_tag: String,
}

impl Default for CrmfLedger {
    fn default() -> Self {
        Self::new()
    }
}

impl CrmfLedger {
    pub fn new() -> Self {
        Self {
            archivum: ArchivumLedger::new(),
            records: Vec::new(),
            domain_tag: String::from("archivum-domain"),
        }
    }

    /// Declare this ledger's domain tag (used by the `Compatible()` gate).
    pub fn with_domain_tag(mut self, tag: impl Into<String>) -> Self {
        self.domain_tag = tag.into();
        self
    }

    /// The ledger's declared domain tag.
    pub fn domain_tag(&self) -> &str {
        &self.domain_tag
    }

    /// Append a sealed CRMF envelope to the hash-chained audit chain.
    ///
    /// Verifies the envelope seal, enforces the `Compatible()` domain-tag
    /// gate, rejects duplicate anchors, and links the new witness to the
    /// current head of the chain.
    pub fn append_envelope(&mut self, envelope: &CrmfEnvelope) -> Result<(), CrmfError> {
        envelope.verify()?;

        let state_hash = envelope.seal.dual_anchor.sha256_hex.clone();
        let sealed_domain = envelope.seal.poseidon2.domain_tag.clone();
        let w = Witness {
            state_hash,
            event_type: envelope.payload.event_type.clone(),
            timestamp: envelope.timestamp.timestamp(),
            commit_hash: Some(envelope.seal.bcs_hash.clone()),
            previous_hash: None,
        };

        self.archivum
            .append_compatible(w, &sealed_domain, &self.domain_tag)
            .map_err(|e| match e {
                ArchivumError::DuplicateWitness { state_hash } => {
                    CrmfError::DuplicateEnvelope { state_hash }
                }
                ArchivumError::DomainTagMismatch { sealed, store } => {
                    CrmfError::DomainTagMismatch { sealed, store }
                }
                other => CrmfError::Archivum(other),
            })?;

        self.records.push(envelope.clone());
        Ok(())
    }

    /// Re-verify chain validity (recomputed root and linkage).
    pub fn verify_chain(&self) -> bool {
        self.archivum.verify_chain()
    }

    /// The chain commit root.
    pub fn root_hash(&self) -> [u8; 32] {
        self.archivum.root_hash()
    }

    /// Number of sealed envelopes on the chain.
    pub fn len(&self) -> usize {
        self.records.len()
    }

    pub fn is_empty(&self) -> bool {
        self.records.is_empty()
    }

    /// Scan for any seal/chain violations (tamper evidence).
    ///
    /// Re-verifies every envelope's cryptographic seal against its recorded
    /// anchor, asserts each envelope's anchor matches its chain witness, and
    /// re-derives the chain root. Returns a list of human-readable violations.
    pub fn scan_for_violations(&self) -> Vec<String> {
        let mut violations = Vec::new();
        for (i, env) in self.records.iter().enumerate() {
            if env.verify().is_err() {
                violations.push(format!("envelope[{i}] cryptographic seal violation"));
            }
            if let Some(w) = self.archivum.witnesses.get(i) {
                if w.state_hash != env.seal.dual_anchor.sha256_hex {
                    violations.push(format!("envelope[{i}] anchor mismatches chain witness"));
                }
            }
        }
        if !self.archivum.verify_chain() {
            violations.push("chain integrity violation".to_string());
        }
        violations
    }
}