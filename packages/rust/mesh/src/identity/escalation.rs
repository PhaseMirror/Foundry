use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;
use crate::identity::PrivilegeRing;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct EscalationRequest {
    pub agent_did: String,
    pub current_ring: PrivilegeRing,
    pub requested_ring: PrivilegeRing,
    pub reason: String,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct EscalationEvent {
    pub event_id: Uuid,
    pub agent_did: String,
    pub approver_did: String,
    pub from_ring: PrivilegeRing,
    pub to_ring: PrivilegeRing,
    pub outcome: EscalationOutcome,
    pub reason: String,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum EscalationOutcome {
    Approved,
    Denied { cause: String },
}

pub fn approval_payload(event_id: &Uuid, agent_did: &str, requested_ring: PrivilegeRing) -> Vec<u8> {
    format!("{}:{}:{}", event_id, agent_did, requested_ring).into_bytes()
}
