/// Canonical Sponge Configuration (CSC) for ACE Track B circuits.
///
/// Enforces the locked circuit topology required by IFMD v0.1 and
/// patent-bound constraints.

use thiserror::Error;

#[derive(Debug, Error)]
pub enum CircuitViolationError {
    #[error("Topology violation: ACE requires Poseidon2(t={required_t}, r={required_r}), got (t={got_t}, r={got_r})")]
    TopologyViolation {
        required_t: usize,
        required_r: usize,
        got_t: usize,
        got_r: usize,
    },
    #[error("Compiler deviation: ACE must compile to {required} constraints, got {got}")]
    CompilerDeviation { required: usize, got: usize },
}

pub struct CanonicalCircuitBudget;

impl CanonicalCircuitBudget {
    pub const REQUIRED_T: usize = 9;
    pub const REQUIRED_R: usize = 8;

    pub const COST_FWHT: usize = 384;
    pub const COST_POSEIDON_H: usize = 3171;
    pub const COST_POSEIDON_GAMMA: usize = 1500;
    pub const COST_RANGE: usize = 32;

    pub const CANONICAL_TOTAL: usize = Self::COST_FWHT
        + Self::COST_POSEIDON_H
        + Self::COST_POSEIDON_GAMMA
        + Self::COST_RANGE;

    pub fn compute_budget(poseidon_t: usize, poseidon_r: usize) -> Result<usize, CircuitViolationError> {
        if poseidon_t != Self::REQUIRED_T || poseidon_r != Self::REQUIRED_R {
            return Err(CircuitViolationError::TopologyViolation {
                required_t: Self::REQUIRED_T,
                required_r: Self::REQUIRED_R,
                got_t: poseidon_t,
                got_r: poseidon_r,
            });
        }

        Ok(Self::CANONICAL_TOTAL)
    }

    pub fn enforce_compiler_target(compiler_generated_constraints: usize) -> Result<(), CircuitViolationError> {
        if compiler_generated_constraints != Self::CANONICAL_TOTAL {
            return Err(CircuitViolationError::CompilerDeviation {
                required: Self::CANONICAL_TOTAL,
                got: compiler_generated_constraints,
            });
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn budget_constant_is_locked() {
        assert_eq!(CanonicalCircuitBudget::CANONICAL_TOTAL, 5087);
    }

    #[test]
    fn compute_budget_rejects_topology_drift() {
        let err = CanonicalCircuitBudget::compute_budget(8, 8).unwrap_err();
        assert!(matches!(err, CircuitViolationError::TopologyViolation { .. }));
    }

    #[test]
    fn compute_budget_accepts_canonical_topology() {
        let total = CanonicalCircuitBudget::compute_budget(9, 8).unwrap();
        assert_eq!(total, 5087);
    }

    #[test]
    fn enforce_compiler_target_fails_closed() {
        let err = CanonicalCircuitBudget::enforce_compiler_target(5088).unwrap_err();
        assert!(matches!(err, CircuitViolationError::CompilerDeviation { .. }));
    }

    #[test]
    fn enforce_compiler_target_accepts_exact_count() {
        assert!(CanonicalCircuitBudget::enforce_compiler_target(5087).is_ok());
    }
}
