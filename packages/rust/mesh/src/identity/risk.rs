use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc, Duration};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum RiskSeverity {
    Critical,
    High,
    Medium,
    Low,
    Info,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RiskSignal {
    pub signal_type: String,
    pub severity: RiskSeverity,
    pub value: f64, // 0.0 to 1.0
    pub timestamp: DateTime<Utc>,
    pub source: Option<String>,
    pub details: Option<String>,
}

impl RiskSignal {
    pub fn weight(&self) -> f64 {
        match self.severity {
            RiskSeverity::Critical => 1.0,
            RiskSeverity::High => 0.8,
            RiskSeverity::Medium => 0.5,
            RiskSeverity::Low => 0.2,
            RiskSeverity::Info => 0.1,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RiskScore {
    pub agent_did: String,
    pub total_score: u32,
    pub identity_score: u32,
    pub behavior_score: u32,
    pub network_score: u32,
    pub compliance_score: u32,
    pub active_signals: u32,
    pub critical_signals: u32,
}

struct RiskState {
    scores: HashMap<String, RiskScore>,
    signals: HashMap<String, Vec<RiskSignal>>,
}

pub struct RiskScorer {
    state: Arc<RwLock<RiskState>>,
}

impl RiskScorer {
    pub fn new() -> Self {
        Self {
            state: Arc::new(RwLock::new(RiskState {
                scores: HashMap::new(),
                signals: HashMap::new(),
            })),
        }
    }

    pub fn get_score(&self, agent_did: &str) -> Option<RiskScore> {
        let state = self.state.read().unwrap();
        state.scores.get(agent_did).cloned()
    }

    pub fn add_signal(&self, agent_did: &str, signal: RiskSignal) {
        let mut state = self.state.write().unwrap();
        state.signals.entry(agent_did.to_string()).or_default().push(signal.clone());
        
        // Always recalculate score to ensure consistency
        let score = Self::calculate_score(agent_did, &state.signals);
        state.scores.insert(agent_did.to_string(), score);
    }

    pub fn recalculate(&self, agent_did: &str) -> RiskScore {
        let mut state = self.state.write().unwrap();
        let score = Self::calculate_score(agent_did, &state.signals);
        state.scores.insert(agent_did.to_string(), score.clone());
        score
    }

    fn calculate_score(agent_did: &str, signals_map: &HashMap<String, Vec<RiskSignal>>) -> RiskScore {
        let agent_signals = signals_map.get(agent_did).cloned().unwrap_or_default();
        
        let cutoff = Utc::now() - Duration::hours(24);
        let recent_signals: Vec<RiskSignal> = agent_signals
            .into_iter()
            .filter(|s| s.timestamp > cutoff)
            .collect();

        // Placeholder logic: component scores based on signal types and weights
        let mut identity: u32 = 80;
        let mut behavior: u32 = 70;
        let mut network: u32 = 75;
        let mut compliance: u32 = 85;

        for signal in &recent_signals {
            let reduction = (signal.value * signal.weight() * 20.0) as u32;
            if signal.signal_type.starts_with("identity.") { identity = identity.saturating_sub(reduction); }
            if signal.signal_type.starts_with("behavior.") { behavior = behavior.saturating_sub(reduction); }
            if signal.signal_type.starts_with("network.") { network = network.saturating_sub(reduction); }
            if signal.signal_type.starts_with("compliance.") { compliance = compliance.saturating_sub(reduction); }
        }

        let total_score = (identity * 2 + behavior * 3 + network * 2 + compliance * 3) / 10;

        RiskScore {
            agent_did: agent_did.to_string(),
            total_score: total_score.min(1000),
            identity_score: identity.min(100),
            behavior_score: behavior.min(100),
            network_score: network.min(100),
            compliance_score: compliance.min(100),
            active_signals: recent_signals.len() as u32,
            critical_signals: recent_signals.iter().filter(|s| matches!(s.severity, RiskSeverity::Critical)).count() as u32,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_risk_scorer_recalculate() {
        let scorer = RiskScorer::new();
        let agent_did = "did:mesh:test-agent";

        scorer.add_signal(agent_did, RiskSignal {
            signal_type: "identity.failed_auth".to_string(),
            severity: RiskSeverity::High,
            value: 0.5,
            timestamp: Utc::now(),
            source: None,
            details: None,
        });

        let score = scorer.recalculate(agent_did);
        assert!(score.total_score < 500);
        assert_eq!(score.active_signals, 1);
    }
}
