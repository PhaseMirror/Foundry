//! # Sedona Spine Engine
//! Implements the verified logic derived from the Lean 4 formalization.
//! The Engine is the sole source of truth for ESI retention, litigation hold,
//! and spoliation risk calculations.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RiskLevel {
    Critical,
    High,
    Medium,
}

impl ToString for RiskLevel {
    fn to_string(&self) -> String {
        match self {
            RiskLevel::Critical => "Critical".to_string(),
            RiskLevel::High => "High".to_string(),
            RiskLevel::Medium => "Medium".to_string(),
        }
    }
}

/// Represents the authenticated state within the Rust Engine.
pub struct EngineState {
    pub policy_active: bool,
    pub event_log_count: usize,
    pub spoliation_flags: u32,
}

impl EngineState {
    pub fn new(policy_active: bool, event_log_count: usize, spoliation_flags: u32) -> Self {
        Self {
            policy_active,
            event_log_count,
            spoliation_flags,
        }
    }
}

pub struct EsiEngine {
    state: EngineState,
}

impl EsiEngine {
    pub fn new(state: EngineState) -> Self {
        Self { state }
    }

    /// Compute the preservation risk level.
    /// UI/Agents MUST NOT override this logic.
    pub fn compute_risk_level(&self) -> RiskLevel {
        if self.state.spoliation_flags > 0 {
            RiskLevel::Critical
        } else if self.state.policy_active {
            RiskLevel::High
        } else {
            RiskLevel::Medium
        }
    }

    /// Read-only access to state
    pub fn get_state(&self) -> &EngineState {
        &self.state
    }
}

/// Represents a decision emitted to the UI/Agent layer.
pub struct AgentOutput {
    pub narrative: String,
    pub risk: RiskLevel,
}

impl AgentOutput {
    /// Safe generation of output, asserting that the risk is mathematically
    /// pulled straight from the engine, avoiding agent hallucination.
    pub fn generate<F>(engine: &EsiEngine, transform_fn: F) -> Self
    where
        F: FnOnce(&EngineState) -> String,
    {
        Self {
            narrative: transform_fn(engine.get_state()),
            risk: engine.compute_risk_level(),
        }
    }
}
