use crate::math::certify::AceCertificate;
use crate::math::types::StepInfo;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditEvent {
    pub sequence: usize,
    pub event_hash: String,
    pub chain_hash: String,
    pub payload_json: String,
}

pub struct AuditChain {
    events: Vec<AuditEvent>,
    head: String,
}

impl AuditChain {
    pub const GENESIS_HASH: &'static str = "0000000000000000000000000000000000000000000000000000000000000000";

    pub fn new() -> Self {
        Self {
            events: Vec::new(),
            head: Self::GENESIS_HASH.to_string(),
        }
    }

    pub fn append_step(&mut self, info: &StepInfo) -> AuditEvent {
        let mut payload = HashMap::new();
        payload.insert("type", serde_json::json!("step"));
        payload.insert("step", serde_json::json!(info.step));
        payload.insert("q", serde_json::json!(info.q));
        payload.insert("epsilon", serde_json::json!(info.epsilon));
        payload.insert("nXi", serde_json::json!(info.n_xi));
        payload.insert("nLam", serde_json::json!(info.n_lam));
        payload.insert("projected", serde_json::json!(info.projected));
        payload.insert("residual", serde_json::json!(info.residual));

        self.append_payload(payload)
    }

    pub fn append_certificate(&mut self, cert: &AceCertificate) -> AuditEvent {
        let mut payload = HashMap::new();
        payload.insert("type", serde_json::json!("certificate"));
        payload.insert("certified", serde_json::json!(cert.certified));
        payload.insert("margin", serde_json::json!(cert.margin));
        payload.insert("q_max", cert.details.get("max_q").cloned().unwrap_or(serde_json::Value::Null));
        payload.insert("tail_bound", serde_json::json!(cert.tail_bound));

        self.append_payload(payload)
    }

    pub fn append_gate(&mut self, step_index: usize, emitted: bool, policy: &str, reason: &str) -> AuditEvent {
        let mut payload = HashMap::new();
        payload.insert("type", serde_json::json!("gate"));
        payload.insert("step", serde_json::json!(step_index));
        payload.insert("emitted", serde_json::json!(emitted));
        payload.insert("policy", serde_json::json!(policy));
        payload.insert("reason", serde_json::json!(reason));

        self.append_payload(payload)
    }

    pub fn append_payload(&mut self, payload: HashMap<&str, serde_json::Value>) -> AuditEvent {
        // Note: serde_json::to_string for HashMap doesn't guarantee key order unless it's a BTreeMap
        // Let's use BTreeMap for canonicalization
        let mut sorted_payload = std::collections::BTreeMap::new();
        for (k, v) in payload {
            sorted_payload.insert(k, v);
        }
        let canonical_json = serde_json::to_string(&sorted_payload).unwrap();

        let mut hasher = Sha256::new();
        hasher.update(canonical_json.as_bytes());
        let event_hash = hex::encode(hasher.finalize());

        let mut chain_hasher = Sha256::new();
        chain_hasher.update(self.head.as_bytes());
        chain_hasher.update(event_hash.as_bytes());
        let chain_hash = hex::encode(chain_hasher.finalize());

        let event = AuditEvent {
            sequence: self.events.len(),
            event_hash,
            chain_hash: chain_hash.clone(),
            payload_json: canonical_json,
        };

        self.events.push(event.clone());
        self.head = chain_hash;
        event
    }

    pub fn verify(&self) -> bool {
        let mut head = Self::GENESIS_HASH.to_string();
        for event in &self.events {
            let mut hasher = Sha256::new();
            hasher.update(event.payload_json.as_bytes());
            let recomputed_event_hash = hex::encode(hasher.finalize());
            if recomputed_event_hash != event.event_hash {
                return false;
            }

            let mut chain_hasher = Sha256::new();
            chain_hasher.update(head.as_bytes());
            chain_hasher.update(event.event_hash.as_bytes());
            let expected_chain_hash = hex::encode(chain_hasher.finalize());
            if expected_chain_hash != event.chain_hash {
                return false;
            }
            head = event.chain_hash.clone();
        }
        true
    }

    pub fn events(&self) -> &[AuditEvent] {
        &self.events
    }

    pub fn head(&self) -> &str {
        &self.head
    }

    pub fn len(&self) -> usize {
        self.events.len()
    }
}
