use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;
use sha2::{Sha256, Digest};

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum DataCategory {
    PersonalData,           // GDPR scope
    FinancialRecord,        // SOX scope
    AuditLog,               // both
    SystemConfig,           // neither
    Unknown,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ActionLogRecord {
    pub record_id: Uuid,
    pub agent_did: String,
    pub action: String,
    pub resource_category: DataCategory,
    pub timestamp: DateTime<Utc>,
    pub outcome: ActionOutcome,
    pub prev_hash: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum ActionOutcome {
    Permitted,
    Denied { rule: String, reason: String },
    DiscoveryEvent { event_json: String },
}

impl ActionLogRecord {
    pub fn canonical_bytes(&self) -> Vec<u8> {
        #[derive(Serialize)]
        struct HashableRecord<'a> {
            record_id: Uuid,
            agent_did: &'a str,
            action: &'a str,
            resource_category: &'a DataCategory,
            timestamp: DateTime<Utc>,
            outcome: &'a ActionOutcome,
        }

        let hashable = HashableRecord {
            record_id: self.record_id,
            agent_did: &self.agent_did,
            action: &self.action,
            resource_category: &self.resource_category,
            timestamp: self.timestamp,
            outcome: &self.outcome,
        };

        serde_json::to_vec(&hashable).expect("ActionLogRecord is always serializable")
    }

    pub fn compute_hash(&self) -> String {
        let mut hasher = Sha256::new();
        hasher.update(self.canonical_bytes());
        hex::encode(hasher.finalize())
    }
}
