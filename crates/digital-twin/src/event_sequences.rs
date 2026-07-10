use anyhow::Result;
use chrono::Utc;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum EventType {
    StateTransition,
    VerificationPassed,
    VerificationFailed,
    RollbackPerformed,
    ContaminationDetected,
    GateAuthorized,
    ManualReview,
    RecoveryInitiated,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum EventSeverity {
    Info,
    Warning,
    Error,
    Critical,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StateEvent {
    pub event_id: String,
    pub event_type: EventType,
    pub severity: EventSeverity,
    pub from_state: u8,
    pub to_state: u8,
    pub timestamp: String,
    pub sequence_number: u32,
    pub actor: Option<String>,
    pub event_data: HashMap<String, serde_json::Value>,
    pub evidence_hash: Option<String>,
}

impl StateEvent {
    pub fn new(
        event_id: String,
        event_type: EventType,
        severity: EventSeverity,
        from_state: u8,
        to_state: u8,
        sequence_number: u32,
        actor: Option<String>,
        event_data: HashMap<String, serde_json::Value>,
        evidence_hash: Option<String>,
    ) -> Result<Self> {
        if event_id.trim().is_empty() {
            anyhow::bail!("event_id required");
        }
        
        Ok(Self {
            event_id,
            event_type,
            severity,
            from_state,
            to_state,
            timestamp: Utc::now().to_rfc3339(),
            sequence_number,
            actor,
            event_data,
            evidence_hash,
        })
    }

    pub fn get_transition_hash(&self) -> String {
        let content = format!("{}:{}->{}:{}", self.event_id, self.from_state, self.to_state, self.sequence_number);
        let mut hasher = Sha256::new();
        hasher.update(content.as_bytes());
        hex::encode(hasher.finalize())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EventSequence {
    pub scenario_id: String,
    pub scenario_name: String,
    pub events: Vec<StateEvent>,
    pub created_at: String,
    pub actor: Option<String>,
    pub description: Option<String>,
    pub tags: HashMap<String, String>,
}

impl EventSequence {
    pub fn new(scenario_id: String, scenario_name: String) -> Result<Self> {
        if scenario_id.trim().is_empty() {
            anyhow::bail!("scenario_id required");
        }
        if scenario_name.trim().is_empty() {
            anyhow::bail!("scenario_name required");
        }

        Ok(Self {
            scenario_id,
            scenario_name,
            events: Vec::new(),
            created_at: Utc::now().to_rfc3339(),
            actor: None,
            description: None,
            tags: HashMap::new(),
        })
    }

    pub fn validate(&self) -> Result<()> {
        for (i, event) in self.events.iter().enumerate() {
            if event.sequence_number as usize != i {
                anyhow::bail!("Events must have contiguous sequence numbers");
            }
        }
        Ok(())
    }

    pub fn get_sequence_hash(&self) -> String {
        let mut hasher = Sha256::new();
        if self.events.is_empty() {
            hasher.update(b"empty");
        } else {
            for event in &self.events {
                hasher.update(event.get_transition_hash().as_bytes());
            }
        }
        hex::encode(hasher.finalize())
    }
}

#[derive(Debug, Clone)]
pub struct ScenarioResult {
    pub scenario_id: String,
    pub scenario_name: String,
    pub success: bool,
    pub events_executed: usize,
    pub events_total: usize,
    pub initial_state: Option<u8>,
    pub final_state: Option<u8>,
    pub sequence_hash: String,
    pub replay_hash: String,
    pub is_deterministic: bool,
    pub executed_at: String,
    pub failure_reason: Option<String>,
}

impl ScenarioResult {
    pub fn get_completion_percentage(&self) -> f64 {
        if self.events_total == 0 {
            return if self.success { 100.0 } else { 0.0 };
        }
        (self.events_executed as f64 / self.events_total as f64) * 100.0
    }

    pub fn get_summary(&self) -> String {
        let completion = self.get_completion_percentage();
        let status = if self.success { "✓ PASS" } else { "✗ FAIL" };
        format!("{} | {} | {}/{} events ({:.0}%) | {:?} -> {:?}", 
            status, self.scenario_name, self.events_executed, self.events_total, 
            completion, self.initial_state, self.final_state)
    }
}

pub struct ScenarioRunner {
    pub sequence: EventSequence,
    pub replay_hash_before: String,
    pub current_event_index: usize,
    pub execution_state: u8,
    pub events_replayed: Vec<StateEvent>,
    pub failed: bool,
    pub failure_reason: Option<String>,
}

impl ScenarioRunner {
    pub fn new(sequence: EventSequence) -> Self {
        let hash = sequence.get_sequence_hash();
        Self {
            sequence,
            replay_hash_before: hash,
            current_event_index: 0,
            execution_state: 0,
            events_replayed: Vec::new(),
            failed: false,
            failure_reason: None,
        }
    }

    pub fn reset(&mut self) {
        self.current_event_index = 0;
        self.execution_state = 0;
        self.events_replayed.clear();
        self.failed = false;
        self.failure_reason = None;
    }

    pub fn step(&mut self) -> Result<bool> {
        if self.failed || self.current_event_index >= self.sequence.events.len() {
            return Ok(false);
        }

        let event = &self.sequence.events[self.current_event_index];
        
        if event.from_state != self.execution_state && self.current_event_index > 0 {
            self.failed = true;
            self.failure_reason = Some(format!("State mismatch: expected {}, got {}", event.from_state, self.execution_state));
            return Ok(false);
        }

        use crate::enforcement_state::{EnforcementBits, EnforcementLegitimacyPredicate};
        
        let target_bits = EnforcementBits::from_bits_truncate(event.to_state);
        if !EnforcementLegitimacyPredicate::is_legitimate(target_bits) {
            self.failed = true;
            self.failure_reason = Some(format!("Invalid state transition to illegitimate state {}", event.to_state));
            return Ok(false);
        }

        self.execution_state = event.to_state;
        self.events_replayed.push(event.clone());
        self.current_event_index += 1;

        Ok(true)
    }
    
    pub fn run_all(&mut self) -> Result<ScenarioResult> {
        self.reset();
        
        let initial_state = self.sequence.events.first().map(|e| e.from_state);
        
        while self.step()? {}

        let final_state = Some(self.execution_state);
        
        let mut replayed_sequence = EventSequence::new("replay".to_string(), "replay".to_string())?;
        replayed_sequence.events = self.events_replayed.clone();
        
        let replay_hash = replayed_sequence.get_sequence_hash();
        let is_deterministic = replay_hash == self.replay_hash_before;
        
        if !is_deterministic && !self.failed {
            self.failed = true;
            self.failure_reason = Some("Replay divergence detected".to_string());
        }

        Ok(ScenarioResult {
            scenario_id: self.sequence.scenario_id.clone(),
            scenario_name: self.sequence.scenario_name.clone(),
            success: !self.failed && self.events_replayed.len() == self.sequence.events.len(),
            events_executed: self.events_replayed.len(),
            events_total: self.sequence.events.len(),
            initial_state,
            final_state,
            sequence_hash: self.replay_hash_before.clone(),
            replay_hash,
            is_deterministic,
            executed_at: Utc::now().to_rfc3339(),
            failure_reason: self.failure_reason.clone(),
        })
    }
}
