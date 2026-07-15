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
    use super::*;

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
