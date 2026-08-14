use crate::math::audit::AuditChain;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LambdaTraceEvent {
    pub schema_id: String,
    pub event_type: String,
    pub sequence: usize,
    pub chain_hash: String,
    pub payload: serde_json::Value,
    pub capability_token: String,
    pub timestamp: f64,
    pub source: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubmissionReceipt {
    pub batch_id: String,
    pub events_submitted: usize,
    pub merkle_root: String,
    pub status: String,
    pub timestamp: f64,
    pub poseidon_merkle_root: Option<String>,
}

pub struct LambdaTraceBridge {
    pub session_id: String,
    pub capability_token: String,
    pending: Vec<LambdaTraceEvent>,
}

impl LambdaTraceBridge {
    pub const SCHEMA_STEP: &'static str = "pirtm.step.v1";
    pub const SCHEMA_CERTIFICATE: &'static str = "pirtm.certificate.v1";
    pub const SCHEMA_GATE: &'static str = "pirtm.gate.v1";
    pub const SCHEMA_AGGREGATE: &'static str = "pirtm.aggregate.v1";

    pub fn new(session_id: &str, capability_token: &str) -> Self {
        Self {
            session_id: session_id.to_string(),
            capability_token: capability_token.to_string(),
            pending: Vec::new(),
        }
    }

    pub fn translate(&mut self, chain: &AuditChain) -> Vec<LambdaTraceEvent> {
        let mut events = Vec::new();
        for audit_event in chain.events() {
            let payload: serde_json::Value = serde_json::from_str(&audit_event.payload_json).unwrap();
            let event_name = payload.get("type").and_then(|t| t.as_str()).unwrap_or("unknown");
            let schema_id = match event_name {
                "step" => Self::SCHEMA_STEP,
                "certificate" => Self::SCHEMA_CERTIFICATE,
                "gate" => Self::SCHEMA_GATE,
                "aggregate_certificate" => Self::SCHEMA_AGGREGATE,
                _ => "pirtm.unknown.v1", // Simplified
            };
            let trace_event = LambdaTraceEvent {
                schema_id: schema_id.to_string(),
                event_type: format!("pirtm.{}", event_name),
                sequence: audit_event.sequence,
                chain_hash: audit_event.chain_hash.clone(),
                payload: payload.clone(),
                capability_token: self.capability_token.clone(),
                timestamp: SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs_f64(),
                source: format!("pirtm:{}", self.session_id),
            };
            events.push(trace_event.clone());
            self.pending.push(trace_event);
        }
        events
    }

    pub fn batch_submit(&mut self) -> SubmissionReceipt {
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs_f64();
        if self.pending.is_empty() {
            return SubmissionReceipt {
                batch_id: "empty".to_string(),
                events_submitted: 0,
                merkle_root: "0".repeat(64),
                poseidon_merkle_root: Some("0".repeat(64)),
                status: "empty".to_string(),
                timestamp: now,
            };
        }

        let hashes: Vec<String> = self.pending.iter().map(|e| e.chain_hash.clone()).collect();
        let merkle_root = self.compute_merkle_root(&hashes);
        let poseidon_merkle_root = self.compute_poseidon_merkle_root(&hashes);
        
        let mut hasher = Sha256::new();
        hasher.update(format!("{}:{}:{}", self.session_id, merkle_root, now).as_bytes());
        let batch_id = hex::encode(hasher.finalize())[..16].to_string();

        let receipt = SubmissionReceipt {
            batch_id,
            events_submitted: self.pending.len(),
            merkle_root,
            poseidon_merkle_root: Some(poseidon_merkle_root),
            status: "dry_run".to_string(),
            timestamp: now,
        };

        self.pending.clear();
        receipt
    }

    fn compute_merkle_root(&self, hashes: &[String]) -> String {
        if hashes.is_empty() {
            return "0".repeat(64);
        }

        let mut layer = hashes.to_vec();
        while layer.len() > 1 {
            let mut next_layer = Vec::new();
            for i in (0..layer.len()).step_by(2) {
                let left = &layer[i];
                let right = if i + 1 < layer.len() { &layer[i + 1] } else { left };
                let mut hasher = Sha256::new();
                hasher.update(left.as_bytes());
                hasher.update(right.as_bytes());
                next_layer.push(hex::encode(hasher.finalize()));
            }
            layer = next_layer;
        }
        layer[0].clone()
    }

    fn poseidon_compat_hash(&self, value: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(format!("poseidon:{}", value).as_bytes());
        hex::encode(hasher.finalize())
    }

    fn compute_poseidon_merkle_root(&self, hashes: &[String]) -> String {
        if hashes.is_empty() {
            return "0".repeat(64);
        }

        let mut layer: Vec<String> = hashes.iter().map(|h| self.poseidon_compat_hash(h)).collect();
        while layer.len() > 1 {
            let mut next_layer = Vec::new();
            for i in (0..layer.len()).step_by(2) {
                let left = &layer[i];
                let right = if i + 1 < layer.len() { &layer[i + 1] } else { left };
                next_layer.push(self.poseidon_compat_hash(&format!("{}{}", left, right)));
            }
            layer = next_layer;
        }
        layer[0].clone()
    }
}
