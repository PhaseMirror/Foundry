//! # CRMF (Cryptographic Record Management Framework)
//!
//! Replacing legacy WORM storage, CRMF acts as the active serialization,
//! record-management, and transport infrastructure. It binds state transitions,
//! policy decisions, and verification metrics into tamper-evident event envelopes
//! authenticated via dual cryptographic anchors (SHA-256 and Ed25519) and
//! Poseidon2 sponge commitments.
//!
//! ## Dataflow
//! 1. State Mutation & Ingestion
//! 2. Runtime Certification (ACE)
//! 3. Cryptographic Sealing (CRMF) ← this crate
//! 4. Permanent Archival (Λ^p-Archivum)

use ed25519_dalek::{Signature, Signer};
use chrono::Utc;
use std::collections::BTreeMap;

use archivum::{ArchivumLedger, Witness, StoredArtifact, ArchivumError};
use archivum::prime_index::LambdaPStore;

pub mod envelope;
pub mod seal;
pub mod ledger;
pub mod bcs;
pub mod poseidon2;

pub use envelope::{CrmfEnvelope, EnvelopePayload, EnvelopeMetadata};
pub use seal::{CrmfSeal, DualAnchor};
pub use poseidon2::Poseidon2Commitment;
pub use bcs::BcsError;
pub use ledger::CrmfLedger;

// ---------------------------------------------------------------------------
// CRMF Error types
// ---------------------------------------------------------------------------

#[derive(Debug, thiserror::Error)]
pub enum CrmfError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
    #[error("Serialization error: {0}")]
    Serialization(String),
    #[error("Signature verification failed")]
    SignatureVerificationFailed,
    #[error("Seal integrity violation")]
    SealViolation,
    #[error("Invalid key material")]
    InvalidKey,
    #[error("Archivum error: {0}")]
    Archivum(#[from] ArchivumError),
    #[error("BCS error: {0}")]
    Bcs(#[from] crate::bcs::BcsError),
}

// ---------------------------------------------------------------------------
// Key management (Ed25519)
// ---------------------------------------------------------------------------

use ed25519_dalek::{SigningKey, VerifyingKey};

/// Ed25519 keypair for CRMF event envelope signing.
#[derive(Debug, Clone)]
pub struct CrmfKeypair {
    pub public: VerifyingKey,
    pub secret: SigningKey,
}

impl CrmfKeypair {
    /// Generate a new random Ed25519 keypair.
    pub fn generate() -> Self {
        let mut csprng = rand::rngs::OsRng;
        let secret = SigningKey::generate(&mut csprng);
        let public = VerifyingKey::from(&secret);
        Self { public, secret }
    }

    pub fn public_key(&self) -> &VerifyingKey {
        &self.public
    }

    pub fn sign(&self, message: &[u8]) -> Signature {
        self.secret.sign(message)
    }
}

// ---------------------------------------------------------------------------
// Integration helpers
// ---------------------------------------------------------------------------

/// Seal a CRMF envelope and store it in the Λ^p-Archivum.
pub fn seal_and_store(
    envelope: &CrmfEnvelope,
    seal: &CrmfSeal,
    store: &mut LambdaPStore,
    ledger: &mut ArchivumLedger,
) -> Result<String, CrmfError> {
    let payload = serde_json::to_vec(envelope)?;
    let artifact = StoredArtifact::new(payload, BTreeMap::new())
        .with_previous(seal.dual_anchor.sha256_hex.clone());

    let hex = store.store(artifact)?;

    let witness = Witness {
        state_hash: hex.clone(),
        event_type: "crmf_seal".to_string(),
        timestamp: Utc::now().timestamp(),
        commit_hash: Some(seal.dual_anchor.sha256_hex.clone()),
        previous_hash: Some(seal.dual_anchor.sha256_hex.clone()),
    };

    ledger.append(witness)?;
    Ok(hex)
}
