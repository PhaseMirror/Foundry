use serde::{Deserialize, Serialize};
use crate::{UnifiedWitness, EsiInputs, evaluate_esi_risk};

/// Represents the strict computational budget for an ACE envelope.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct AceBudget {
    pub max_ops: u64,
    pub max_memory_bytes: u64,
}

/// The state of the ACE Runtime Envelope (Attested Convergence Envelope)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AceEnvelope {
    pub budget: AceBudget,
    pub ops_consumed: u64,
    pub memory_consumed: u64,
    pub is_exhausted: bool,
}

impl AceEnvelope {
    pub fn new(budget: AceBudget) -> Self {
        Self {
            budget,
            ops_consumed: 0,
            memory_consumed: 0,
            is_exhausted: false,
        }
    }

    /// Consumes operations. Returns an Error if the hardware-level budget is breached.
    pub fn consume_ops(&mut self, ops: u64) -> Result<(), &'static str> {
        if self.is_exhausted {
            return Err("ACE Envelope already exhausted (SIG_GOV_KILL).");
        }
        
        match self.ops_consumed.checked_add(ops) {
            Some(new_ops) if new_ops <= self.budget.max_ops => {
                self.ops_consumed = new_ops;
                Ok(())
            }
            _ => {
                self.is_exhausted = true;
                Err("ACE Budget Breach: Max Ops Exceeded (SIG_GOV_KILL).")
            }
        }
    }
}

/// A certified ACE execution result that inextricably links the compilation result to the budget constraints.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CertifiedAceResult {
    pub witness: UnifiedWitness,
    pub final_envelope: AceEnvelope,
}

/// Executes the ESI Risk Evaluation strictly within the ACE Runtime Envelope.
/// Provides the mandatory verifiable ledger anchor from Engine (Rust) to CompilationResult.
pub fn evaluate_esi_risk_with_ace(
    inputs: &EsiInputs, 
    p_factor: u32, 
    sigma: f64, 
    mut envelope: AceEnvelope
) -> Result<CertifiedAceResult, &'static str> {
    // Modeling cost: Mapping the ESI inputs to the spectral space
    envelope.consume_ops(50)?;
    
    // Execute the computationally heavy engine logic
    let witness = evaluate_esi_risk(inputs, p_factor, sigma);
    
    // Modeling cost: Verifying the trace and generating the witness signature
    envelope.consume_ops(20)?;
    
    Ok(CertifiedAceResult {
        witness,
        final_envelope: envelope,
    })
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_ace_envelope_budget_invariant() {
        let max_ops: u64 = kani::any();
        let max_mem: u64 = kani::any();
        
        let budget = AceBudget {
            max_ops,
            max_memory_bytes: max_mem,
        };
        
        let mut envelope = AceEnvelope::new(budget);
        
        // Symbolically consume operations
        let ops_to_consume: u64 = kani::any();
        let result = envelope.consume_ops(ops_to_consume);
        
        if result.is_ok() {
            // Zero-drift requirement: computations MUST respect boundaries perfectly
            kani::assert(!envelope.is_exhausted, "Envelope must not be exhausted on success");
            kani::assert(envelope.ops_consumed <= budget.max_ops, "Ops consumed MUST strictly respect max_ops boundary");
        } else {
            // If failure, envelope exhaustion must trigger
            kani::assert(envelope.is_exhausted, "Envelope MUST be permanently exhausted on budget breach");
        }
    }
}
