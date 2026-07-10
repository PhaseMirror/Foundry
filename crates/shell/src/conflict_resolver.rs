use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConflictRecord {
    pub conflict_id: String,
    pub conflict_type: String,
    pub module_a: String,
    pub module_b: String,
    pub domain_a: String,
    pub domain_b: String,
    pub prevailing_module: String,
    pub reason_code: String,
    pub override_allowed: bool,
    pub fallback_alternative: Option<String>,
    pub timestamp: String,
}

pub fn resolve_conflict(
    module_a: &str,
    domain_a: &str,
    module_b: &str,
    domain_b: &str,
    rank_a: i32,
    rank_b: i32,
) -> ConflictRecord {
    let prevailing = if rank_a <= rank_b { module_a } else { module_b };
    let loser = if rank_a <= rank_b { module_b } else { module_a };

    ConflictRecord {
        conflict_id: Uuid::new_v4().to_string(),
        conflict_type: "RANK_PRECEDENCE".to_string(),
        module_a: module_a.to_string(),
        module_b: module_b.to_string(),
        domain_a: domain_a.to_string(),
        domain_b: domain_b.to_string(),
        prevailing_module: prevailing.to_string(),
        reason_code: "RANK_PRECEDENCE".to_string(),
        override_allowed: true,
        fallback_alternative: Some(format!("{} output preserved as alternative", loser)),
        timestamp: Utc::now().to_rfc3339(),
    }
}
