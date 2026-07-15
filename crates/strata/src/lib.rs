use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub enum Stratum {
    S0 = 0, // Unverified / experimental
    S2 = 2, // Light verification
    S4 = 4, // Standard production
    S6 = 6, // Full Triple-Lock verification
}

impl Stratum {
    pub fn next(&self) -> Option<Self> {
        match self {
            Self::S0 => Some(Self::S2),
            Self::S2 => Some(Self::S4),
            Self::S4 => Some(Self::S6),
            Self::S6 => None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResourceBudget {
    pub max_compute_cycles: u64,
    pub max_memory_bytes: u64,
    pub max_latency_ns: u64,
}

pub fn budget_for_stratum(s: Stratum) -> ResourceBudget {
    match s {
        Stratum::S0 => ResourceBudget { max_compute_cycles: 1000, max_memory_bytes: 1024, max_latency_ns: 500000 },
        Stratum::S2 => ResourceBudget { max_compute_cycles: 10000, max_memory_bytes: 8192, max_latency_ns: 5000000 },
        Stratum::S4 => ResourceBudget { max_compute_cycles: 100000, max_memory_bytes: 65536, max_latency_ns: 50000000 },
        Stratum::S6 => ResourceBudget { max_compute_cycles: 1000000, max_memory_bytes: 524288, max_latency_ns: 500000000 },
    }
}

#[derive(Debug, Error)]
pub enum StratumError {
    #[error("Resource Budget Exceeded in Stratum {stratum:?}: {reason}")]
    BudgetExceeded { stratum: Stratum, reason: String },
    #[error("Invalid Stratum Transition: {0}")]
    InvalidTransition(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StratumTransition {
    pub from: Stratum,
    pub to: Stratum,
    pub guardian_signature: String,
    pub timestamp: u64,
}

impl StratumTransition {
    pub fn new(from: Stratum, to: Stratum, guardian_signature: String) -> Result<Self, StratumError> {
        if from.next() != Some(to) {
            return Err(StratumError::InvalidTransition("Target stratum must be immediately next stratum".into()));
        }
        Ok(Self {
            from,
            to,
            guardian_signature,
            timestamp: 0, // In practice, populated securely
        })
    }
}

pub struct BudgetTracker {
    stratum: Stratum,
    consumed_cycles: u64,
    consumed_memory: u64,
    consumed_latency: u64,
}

impl BudgetTracker {
    pub fn new(stratum: Stratum) -> Self {
        Self {
            stratum,
            consumed_cycles: 0,
            consumed_memory: 0,
            consumed_latency: 0,
        }
    }

    pub fn consume(&mut self, cycles: u64, memory: u64, latency: u64) -> Result<(), StratumError> {
        let budget = budget_for_stratum(self.stratum);
        
        let new_cycles = self.consumed_cycles.saturating_add(cycles);
        let new_memory = self.consumed_memory.saturating_add(memory);
        let new_latency = self.consumed_latency.saturating_add(latency);

        if new_cycles > budget.max_compute_cycles {
            return Err(StratumError::BudgetExceeded {
                stratum: self.stratum,
                reason: "max_compute_cycles".into(),
            });
        }
        if new_memory > budget.max_memory_bytes {
            return Err(StratumError::BudgetExceeded {
                stratum: self.stratum,
                reason: "max_memory_bytes".into(),
            });
        }
        if new_latency > budget.max_latency_ns {
            return Err(StratumError::BudgetExceeded {
                stratum: self.stratum,
                reason: "max_latency_ns".into(),
            });
        }

        self.consumed_cycles = new_cycles;
        self.consumed_memory = new_memory;
        self.consumed_latency = new_latency;

        Ok(())
    }
}

pub struct StratumGuard<'a> {
    pub tracker: &'a mut BudgetTracker,
}

impl<'a> StratumGuard<'a> {
    pub fn new(tracker: &'a mut BudgetTracker) -> Self {
        Self { tracker }
    }
    
    pub fn assert_authority(&self, req_stratum: Stratum) -> Result<(), StratumError> {
        if self.tracker.stratum < req_stratum {
            return Err(StratumError::InvalidTransition("Insufficient authority for stratum".into()));
        }
        Ok(())
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_budget_monotonicity_and_enforcement() {
        let s_idx: u8 = kani::any();
        let stratum = match s_idx % 4 {
            0 => Stratum::S0,
            1 => Stratum::S2,
            2 => Stratum::S4,
            _ => Stratum::S6,
        };
        
        let mut tracker = BudgetTracker::new(stratum);
        
        let cycles: u64 = kani::any();
        let memory: u64 = kani::any();
        let latency: u64 = kani::any();
        
        let budget = budget_for_stratum(stratum);
        
        match tracker.consume(cycles, memory, latency) {
            Ok(_) => {
                kani::assert(tracker.consumed_cycles <= budget.max_compute_cycles, "Budget enforcement failed on cycles");
                kani::assert(tracker.consumed_memory <= budget.max_memory_bytes, "Budget enforcement failed on memory");
                kani::assert(tracker.consumed_latency <= budget.max_latency_ns, "Budget enforcement failed on latency");
            }
            Err(_) => {
                // Should only fail if it would exceed bounds
                kani::assert(
                    tracker.consumed_cycles.saturating_add(cycles) > budget.max_compute_cycles ||
                    tracker.consumed_memory.saturating_add(memory) > budget.max_memory_bytes ||
                    tracker.consumed_latency.saturating_add(latency) > budget.max_latency_ns,
                    "Rejected valid consumption"
                );
            }
        }
    }
}
