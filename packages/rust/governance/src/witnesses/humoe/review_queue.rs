use serde::{Deserialize, Serialize};
use serde_json::Value;
use crate::witnesses::humoe::operator_auth::{OperatorRegistry};
use validator::Validate;

#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct ExceptionEnvelope {
    pub id: String,
    pub timestamp: String, // Ideally use DateTime<Utc> but keeping as String for now to match schema format
    pub source: String,
    pub payload: Value,
    pub predicate: String,
    pub proposed_action: String,
    #[serde(default)]
    pub context: Option<Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct DecisionRecord {
    pub event_id: String,
    pub reviewer_id: String,
    pub decision: String,
    pub rationale: String,
    pub timestamp: String,
    #[serde(default)]
    pub provenance: Option<Value>,
    #[serde(default)]
    pub escalation: bool,
}

pub struct HOXReviewQueue {
    queue: Vec<ExceptionEnvelope>,
    decisions: Vec<DecisionRecord>,
}

impl HOXReviewQueue {
    pub fn new() -> Self {
        Self {
            queue: Vec::new(),
            decisions: Vec::new(),
        }
    }

    pub fn ingest_exception(&mut self, envelope: ExceptionEnvelope) -> Result<(), String> {
        envelope.validate().map_err(|e| format!("Validation failed: {}", e))?;
        self.queue.push(envelope);
        Ok(())
    }

    pub fn claim_next(&mut self) -> Option<ExceptionEnvelope> {
        if !self.queue.is_empty() {
            Some(self.queue.remove(0))
        } else {
            None
        }
    }

    pub fn record_decision(&mut self, decision: DecisionRecord, registry: &OperatorRegistry) -> Result<(), String> {
        decision.validate().map_err(|e| format!("Validation failed: {}", e))?;
        
        let operator = registry.get_operator(&decision.reviewer_id)
            .ok_or_else(|| format!("Unknown operator: {}", decision.reviewer_id))?;
        
        if !operator.can_act_on(&decision.decision, decision.escalation) {
            return Err(format!(
                "Operator {} ({:?}) not authorized for action '{}' (escalation={})",
                decision.reviewer_id, operator.role, decision.decision, decision.escalation
            ));
        }

        self.decisions.push(decision);
        Ok(())
    }

    pub fn get_all_decisions(&self) -> Vec<DecisionRecord> {
        self.decisions.clone()
    }
}
