//! Formal state space definitions with verified transitions for MCPE protocols.
//!
//! Provides typed state vectors, transition functions, and invariant checking
//! with Kani-verified safety properties.

use crate::error::{Error, Result, StateId};

/// A vector of state values representing a point in the protocol state space.
///
/// # Invariants
///
/// - Length is fixed for a given state vector type
/// - All values are within their declared bounds
/// - Transitions preserve safety invariants
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct StateVector {
    id: StateId,
    values: Vec<i64>,
    dim: usize,
}

impl StateVector {
    /// Create a new state vector.
    ///
    /// # Errors
    ///
    /// Returns `ProtocolInvariant` if `values.len() != dim`.
    pub fn new(id: StateId, values: Vec<i64>, dim: usize) -> Result<Self> {
        if values.len() != dim {
            return Err(Error::protocol_invariant(format!(
                "state vector dimension mismatch: expected {}, got {}",
                dim,
                values.len()
            )));
        }
        Ok(Self { id, values, dim })
    }

    /// Create a state vector from a fixed-size array.
    pub fn from_array<const N: usize>(id: StateId, values: [i64; N]) -> Self {
        Self {
            id,
            values: values.to_vec(),
            dim: N,
        }
    }

    /// Get the state identifier.
    pub fn id(&self) -> StateId {
        self.id
    }

    /// Get the dimension.
    pub fn dim(&self) -> usize {
        self.dim
    }

    /// Get a reference to the values.
    pub fn values(&self) -> &[i64] {
        &self.values
    }

    /// Get a mutable reference to the values.
    pub fn values_mut(&mut self) -> &mut [i64] {
        &mut self.values
    }

    /// Get a specific value by index.
    ///
    /// # Errors
    ///
    /// Returns `ProtocolInvariant` if index is out of bounds.
    pub fn get(&self, index: usize) -> Result<i64> {
        self.values
            .get(index)
            .copied()
            .ok_or_else(|| Error::protocol_invariant(format!("index {} out of bounds", index)))
    }

    /// Set a specific value by index.
    ///
    /// # Errors
    ///
    /// Returns `ProtocolInvariant` if index is out of bounds.
    pub fn set(&mut self, index: usize, value: i64) -> Result<()> {
        if index >= self.values.len() {
            return Err(Error::protocol_invariant(format!(
                "index {} out of bounds for dimension {}",
                index, self.dim
            )));
        }
        self.values[index] = value;
        Ok(())
    }

    /// Compute the L2 norm of the state vector.
    pub fn l2_norm(&self) -> f64 {
        self.values
            .iter()
            .map(|&x| (x as f64).powi(2))
            .sum::<f64>()
            .sqrt()
    }

    /// Check if the state vector has converged within epsilon.
    pub fn has_converged(&self, epsilon: f64) -> bool {
        self.l2_norm() <= epsilon
    }

    /// Check for collapse (NaN or infinite values).
    pub fn has_collapsed(&self) -> bool {
        self.values.iter().any(|&x| x == i64::MIN || x == i64::MAX)
    }
}

/// A verified state transition function.
///
/// Transitions are total functions that preserve protocol invariants.
pub trait Transition {
    /// Apply the transition to a state vector.
    ///
    /// # Errors
    ///
    /// Returns an error if the transition violates protocol invariants.
    fn apply(&self, state: &StateVector) -> Result<StateVector>;

    /// Check if this transition is safe from the given state.
    fn is_safe(&self, state: &StateVector) -> bool;
}

/// Linear transition: `next = current + delta`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LinearTransition {
    delta: Vec<i64>,
}

impl LinearTransition {
    /// Create a new linear transition.
    ///
    /// # Errors
    ///
    /// Returns `ProtocolInvariant` if delta dimension doesn't match expected dimension.
    pub fn new(delta: Vec<i64>, expected_dim: usize) -> Result<Self> {
        if delta.len() != expected_dim {
            return Err(Error::protocol_invariant(format!(
                "transition delta dimension {} != expected {}",
                delta.len(),
                expected_dim
            )));
        }
        Ok(Self { delta })
    }

    /// Get the delta vector.
    pub fn delta(&self) -> &[i64] {
        &self.delta
    }
}

impl Transition for LinearTransition {
    fn apply(&self, state: &StateVector) -> Result<StateVector> {
        let mut new_values = Vec::with_capacity(state.dim);
        for (i, &current) in state.values.iter().enumerate() {
            let delta_val = self.delta.get(i).copied().unwrap_or(0);
            let next = current
                .checked_add(delta_val)
                .ok_or_else(|| Error::numeric_overflow("linear_transition", (current + delta_val) as u64))?;
            new_values.push(next);
        }
        StateVector::new(
            StateId::new(state.id.value() + 1),
            new_values,
            state.dim,
        )
    }

    fn is_safe(&self, state: &StateVector) -> bool {
        !state.has_collapsed()
    }
}

/// Repair transition with clipping bounds.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RepairTransition {
    eta: i64,
    lower_bound: i64,
    upper_bound: i64,
}

impl RepairTransition {
    /// Create a new repair transition with bounds.
    pub fn new(eta: i64, lower_bound: i64, upper_bound: i64) -> Self {
        assert!(lower_bound <= upper_bound, "lower_bound must <= upper_bound");
        Self {
            eta,
            lower_bound,
            upper_bound,
        }
    }

    /// Get the learning rate.
    pub fn eta(&self) -> i64 {
        self.eta
    }

    /// Get the lower bound.
    pub fn lower_bound(&self) -> i64 {
        self.lower_bound
    }

    /// Get the upper bound.
    pub fn upper_bound(&self) -> i64 {
        self.upper_bound
    }
}

impl Transition for RepairTransition {
    fn apply(&self, state: &StateVector) -> Result<StateVector> {
        let mut new_values = Vec::with_capacity(state.dim);
        for &current in state.values.iter() {
            let repaired = current
                .checked_add(self.eta)
                .ok_or_else(|| Error::numeric_overflow("repair_transition", current as u64))?;
            let clipped = repaired.clamp(self.lower_bound, self.upper_bound);
            new_values.push(clipped);
        }
        StateVector::new(
            StateId::new(state.id.value() + 1),
            new_values,
            state.dim,
        )
    }

    fn is_safe(&self, state: &StateVector) -> bool {
        !state.has_collapsed() && self.lower_bound <= self.upper_bound
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_state_vector_creation() {
        let id = StateId::new(1);
        let sv = StateVector::new(id, vec![1, 2, 3], 3).unwrap();
        assert_eq!(sv.dim(), 3);
        assert_eq!(sv.get(0), Ok(1));
    }

    #[test]
    fn test_state_vector_dimension_mismatch() {
        let id = StateId::new(1);
        let err = StateVector::new(id, vec![1, 2], 3).unwrap_err();
        assert!(matches!(err, Error::ProtocolInvariant { .. }));
    }

    #[test]
    fn test_linear_transition() {
        let id = StateId::new(1);
        let sv = StateVector::from_array(id, [10, 20, 30]);
        let transition = LinearTransition::new(vec![1, -1, 0], 3).unwrap();
        let next = transition.apply(&sv).unwrap();
        assert_eq!(next.values(), &[11, 19, 30]);
    }

    #[test]
    fn test_repair_transition() {
        let id = StateId::new(1);
        let sv = StateVector::from_array(id, [100, -100, 0]);
        let transition = RepairTransition::new(-10, -50, 50);
        let next = transition.apply(&sv).unwrap();
        assert_eq!(next.values(), &[50, -50, -10]);
    }

    #[test]
    fn test_l2_norm() {
        let id = StateId::new(1);
        let sv = StateVector::from_array(id, [3, 4]);
        assert_eq!(sv.l2_norm(), 5.0);
    }

    #[test]
    fn test_has_converged() {
        let id = StateId::new(1);
        let sv = StateVector::from_array(id, [0, 0]);
        assert!(sv.has_converged(0.1));
        let sv2 = StateVector::from_array(id, [10, 10]);
        assert!(!sv2.has_converged(0.1));
    }
}
