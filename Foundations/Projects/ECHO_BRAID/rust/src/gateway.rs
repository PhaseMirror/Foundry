//! `gateway.rs` — Governance Gateway & Dissonance Engine integration for ECHO_BRAID.
//!
//! Connects the Floer-Echo-Bundle state machine to the Sedona Spine:
//! - Materializes `ConflictLog` on CSL constraint violation.
//! - Emits `GovernanceDecision::Lawful(UnifiedWitness)` on verified transitions.
//! - Implements the fail-closed halt protocol.

use serde::{Deserialize, Serialize};
use crate::{
    CSLConstraintConfig, CSLValidationResult, EchoBraidState, ErrorPredictionState,
    UnifiedWitness, generate_unified_witness, validate_csl_constraints,
};

/// ConflictLog: Structured diagnostic record emitted when a transition breaches CSL bounds
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ConflictLog {
    pub time_step: u64,
    pub breach_kind: String,
    pub diagnostic_reason: String,
    pub observed_value: u64,
    pub threshold_limit: u64,
    pub is_fail_closed: bool,
}

/// GovernanceDecision: Authoritative verdict for Sedona Spine ingestion
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum GovernanceDecision {
    Lawful {
        witness: UnifiedWitness,
        validation: CSLValidationResult,
    },
    FailClosedHalt {
        conflict: ConflictLog,
    },
}

/// GovernanceGateway: Validates state transitions and anchors certificates
pub struct GovernanceGateway {
    pub config: CSLConstraintConfig,
}

impl GovernanceGateway {
    pub fn new(config: CSLConstraintConfig) -> Self {
        Self { config }
    }

    pub fn evaluate_transition(
        &self,
        st_prev: &EchoBraidState,
        st_curr: &EchoBraidState,
        pred: &ErrorPredictionState,
    ) -> GovernanceDecision {
        let validation = validate_csl_constraints(&self.config, st_prev, st_curr, pred);

        if validation.is_lawful {
            let witness = generate_unified_witness(st_curr, &validation);
            GovernanceDecision::Lawful { witness, validation }
        } else {
            let (kind, observed, limit) = if pred.delta_current > self.config.max_allowed_error {
                ("PREDICTION_DELTA_OVERFLOW", pred.delta_current, self.config.max_allowed_error)
            } else if st_curr.spectral_coherence < self.config.min_coherence {
                ("COHERENCE_COLLAPSE", st_curr.spectral_coherence, self.config.min_coherence)
            } else {
                let e_prev = st_prev.total_energy();
                let e_curr = st_curr.total_energy();
                let diff = if e_curr >= e_prev { e_curr - e_prev } else { e_prev - e_curr };
                ("ENERGY_VOLATILITY_CEILING", diff, self.config.max_energy_deviation)
            };

            let conflict = ConflictLog {
                time_step: st_curr.time,
                breach_kind: kind.to_string(),
                diagnostic_reason: validation.reason,
                observed_value: observed,
                threshold_limit: limit,
                is_fail_closed: true,
            };

            GovernanceDecision::FailClosedHalt { conflict }
        }
    }
}
