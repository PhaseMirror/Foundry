use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct State {
    pub data: Vec<u8>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComputationBudget {
    pub max_cycles: u64,
    pub max_memory: u64,
    pub max_latency_ns: u64,
}

pub struct InvariantSet {
    pub invariants: Vec<(String, fn(&State) -> bool)>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ACEWitness {
    pub state_hash: [u8; 32],
    pub invariant_checks: Vec<(String, bool)>,
    pub budget_used: u64,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum ACEViolation {
    #[error("budget exceeded: {used} > {limit}")]
    BudgetExceeded { used: u64, limit: u64 },
    #[error("invariant breached: {inv_name}")]
    InvariantBreach { inv_name: String },
}

pub struct ACEEnvelope {
    budget: ComputationBudget,
    invariants: InvariantSet,
    cycles_used: u64,
    witness_trace: Vec<ACEWitness>,
}

impl ACEEnvelope {
    pub fn new(budget: ComputationBudget, invariants: InvariantSet) -> Result<Self, ACEViolation> {
        Ok(Self { budget, invariants, cycles_used: 0, witness_trace: Vec::new() })
    }

    pub fn check_transition(&mut self, state: &State) -> Result<State, ACEViolation> {
        self.cycles_used += 1;
        if self.cycles_used > self.budget.max_cycles {
            return Err(ACEViolation::BudgetExceeded {
                used: self.cycles_used,
                limit: self.budget.max_cycles,
            });
        }
        for (name, check) in &self.invariants.invariants {
            if !check(state) {
                return Err(ACEViolation::InvariantBreach { inv_name: name.clone() });
            }
        }
        let witness = ACEWitness {
            state_hash: blake3::hash(&serde_json::to_vec(state).unwrap()).into(),
            invariant_checks: self.invariants.invariants.iter().map(|(n, c)| (n.clone(), c(state))).collect(),
            budget_used: self.cycles_used,
            timestamp: chrono::Utc::now().timestamp(),
        };
        self.witness_trace.push(witness);
        Ok(state.clone())
    }

    pub fn finalize(self) -> Result<archivum::ACEProof, ACEViolation> {
        Ok(archivum::ACEProof::new(self.witness_trace.len(), self.cycles_used))
    }
}

#[cfg(kani)]
mod verification {

    #[kani::proof]
    fn proof_ace_preserves_invariants_and_budget() {
        let max_cycles: u64 = kani::any();
        kani::assume(max_cycles > 0 && max_cycles < 10);
        
        let budget = ComputationBudget {
            max_cycles,
            max_memory: 1024,
            max_latency_ns: 1000,
        };
        
        let inv = InvariantSet {
            invariants: vec![("test_inv".into(), |_s| true)],
        };
        
        let mut envelope = ACEEnvelope::new(budget, inv).unwrap();
        let state = State { data: vec![0] };
        
        for i in 1..=max_cycles {
            let res = envelope.check_transition(&state);
            kani::assert(res.is_ok(), "Valid transition rejected");
            kani::assert(envelope.cycles_used == i, "Cycles not tracked");
        }
        
        let res_over = envelope.check_transition(&state);
        kani::assert(res_over.is_err(), "Budget exhaustion not detected");
        if let Err(ACEViolation::BudgetExceeded { used, limit }) = res_over {
            kani::assert(used > limit, "Incorrect budget error");
        } else {
            kani::assert(false, "Expected BudgetExceeded error");
        }
    }
}

/// Fail-Closed RSA-mitigation gate (ADR-111 / Lean `SecurityGate.lean`).
///
/// The operator channel carries a `SecurityState`. When the mode is
/// `GovernanceReview`, any RSA-based primitive (`primitive_id == 0`) is
/// prohibited. The ACE guardian must verify `validate_contraction_gate` before
/// executing any operator word; on failure it raises `SIG_GOV_KILL`
/// (Fail-Closed), exactly mirroring the Lean `rsa_governance_fail_closed`
/// theorem.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum SecurityMode {
    Normal,
    GovernanceReview,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SecurityState {
    pub mode: SecurityMode,
    pub primitive_id: u32,
}

impl SecurityState {
    /// `true` iff the channel is permitted to operate under the current mode.
    /// Formal mirror of Lean `validate_contraction_gate` /
    /// `is_lawful_operation`.
    pub fn validate_contraction_gate(&self) -> bool {
        match (&self.mode, self.primitive_id) {
            (SecurityMode::GovernanceReview, 0) => false, // Fail-Closed
            _ => true,
        }
    }
}

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum GateError {
    #[error("RSA primitive prohibited in GovernanceReview mode (SIG_GOV_KILL)")]
    SecurityViolation,
}

impl SecurityState {
    /// Process an operator word under the Fail-Closed gate. Returns
    /// `GateError::SecurityViolation` (which the guardian treats as
    /// `SIG_GOV_KILL`) when the gate is violated.
    pub fn process_operator_word(&self) -> Result<(), GateError> {
        if !self.validate_contraction_gate() {
            return Err(GateError::SecurityViolation);
        }
        Ok(())
    }
}

#[cfg(test)]
mod security_gate_tests {
    use super::*;

    fn rsa_review() -> SecurityState {
        SecurityState { mode: SecurityMode::GovernanceReview, primitive_id: 0 }
    }
    fn rsa_normal() -> SecurityState {
        SecurityState { mode: SecurityMode::Normal, primitive_id: 0 }
    }
    fn prime_review() -> SecurityState {
        SecurityState { mode: SecurityMode::GovernanceReview, primitive_id: 1 }
    }

    #[test]
    fn fail_closed_blocks_rsa_in_review() {
        assert!(!rsa_review().validate_contraction_gate());
        assert_eq!(rsa_review().process_operator_word(), Err(GateError::SecurityViolation));
    }

    #[test]
    fn legacy_rsa_allowed_in_normal() {
        assert!(rsa_normal().validate_contraction_gate());
        assert_eq!(rsa_normal().process_operator_word(), Ok(()));
    }

    #[test]
    fn prime_indexed_allowed_in_review() {
        assert!(prime_review().validate_contraction_gate());
        assert_eq!(prime_review().process_operator_word(), Ok(()));
    }
}
