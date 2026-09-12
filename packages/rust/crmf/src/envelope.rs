//! Tamper-evident CRMF event envelopes.
//!
//! Every state transition, policy decision, and verification metric is bound
//! into an envelope with complete provenance and dual cryptographic anchors.

use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use std::collections::BTreeMap;

use crate::seal::CrmfSeal;
use crate::bcs;
use crate::CrmfKeypair;
use crate::CrmfError;

/// The payload carried inside a CRMF envelope.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnvelopePayload {
    pub event_type: String,
    pub data: serde_json::Value,
    pub proof_hashes: Vec<String>,
}

/// Metadata attached to every CRMF envelope.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnvelopeMetadata {
    pub source: String,
    pub epoch: String,
    pub lawful_recursion_hash: Option<String>,
    pub wardmonitor_status: Option<String>,
    pub mtpi_certifier_drift: Option<f64>,
    pub tags: BTreeMap<String, String>,
}

impl EnvelopeMetadata {
    pub fn new(source: &str) -> Self {
        Self {
            source: source.to_string(),
            epoch: Utc::now().timestamp().to_string(),
            lawful_recursion_hash: None,
            wardmonitor_status: None,
            mtpi_certifier_drift: None,
            tags: BTreeMap::new(),
        }
    }

    pub fn with_lawful_hash(mut self, hash: &str) -> Self {
        self.lawful_recursion_hash = Some(hash.to_string());
        self
    }

    pub fn with_wardmonitor(mut self, status: &str) -> Self {
        self.wardmonitor_status = Some(status.to_string());
        self
    }

    pub fn with_drift(mut self, drift: f64) -> Self {
        self.mtpi_certifier_drift = Some(drift);
        self
    }
}

/// A complete CRMF envelope wrapping an execution payload with cryptographic proof.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrmfEnvelope {
    pub payload: EnvelopePayload,
    pub metadata: EnvelopeMetadata,
    pub seal: CrmfSeal,
    pub timestamp: DateTime<Utc>,
}

impl CrmfEnvelope {
    /// Create a new CRMF envelope and seal it.
    pub fn seal(
        payload: EnvelopePayload,
        metadata: EnvelopeMetadata,
        domain_tag: &str,
        keypair: &CrmfKeypair,
    ) -> Self {
        let bcs_payload = bcs::serialize(&payload).expect("BCS serialization infallible for EnvelopePayload");
        let seal = CrmfSeal::new(&bcs_payload, domain_tag, keypair);

        Self {
            payload,
            metadata,
            seal,
            timestamp: Utc::now(),
        }
    }

    /// Verify the envelope's cryptographic seal.
    pub fn verify(&self) -> Result<(), CrmfError> {
        let bcs_payload = bcs::serialize(&self.payload)?;
        self.seal.verify(&bcs_payload)
    }

    /// BCS-serialize the envelope for storage/transport.
    pub fn to_bcs(&self) -> Result<Vec<u8>, CrmfError> {
        Ok(bcs::serialize(self)?)
    }
}
