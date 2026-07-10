use thiserror::Error;

#[derive(Debug, Error)]
pub enum AceError {
    #[error("ACE Budget Exceeded: required {required}, max {max}")]
    BudgetExceeded { required: usize, max: usize },
    #[error("Invariant Violation: {0}")]
    InvariantViolation(String),
}

/// The ACE Constraint Budget Engine for Phase C
pub struct AceConstraintEngine {
    pub max_compute_budget: usize,
}

impl AceConstraintEngine {
    pub fn new(max_compute_budget: usize) -> Self {
        Self { max_compute_budget }
    }

    /// Evaluates structural bounds against the multiplicity invariants
    pub fn verify_budget(&self, requested_budget: usize) -> Result<(), AceError> {
        if requested_budget > self.max_compute_budget {
            return Err(AceError::BudgetExceeded {
                required: requested_budget,
                max: self.max_compute_budget,
            });
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_node_reduction_within_budget() {
        let engine = AceConstraintEngine::new(1000);
        let sample_reduction_budget = 450;
        
        let result = engine.verify_budget(sample_reduction_budget);
        assert!(result.is_ok());
    }

    #[test]
    fn test_node_reduction_overflow_trap() {
        let engine = AceConstraintEngine::new(1000);
        let overflow_reduction_budget = 1200;
        
        let result = engine.verify_budget(overflow_reduction_budget);
        assert!(result.is_err());
        
        if let Err(AceError::BudgetExceeded { required, max }) = result {
            assert_eq!(required, 1200);
            assert_eq!(max, 1000);
        } else {
            panic!("Expected BudgetExceeded error");
        }
    }
}

