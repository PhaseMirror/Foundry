use serde::{Deserialize, Serialize};
use std::fmt::Debug;

/// Represents the Multiplicity Functor binding a raw syntactic AST block
/// into a formally typed semantic signature suitable for governance verification.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Sig<T> {
    pub ast_payload: T,
    pub prime_index: usize,
    pub weight: f64,
    pub topological_defect: f64,
}

impl<T> Sig<T> {
    /// Applies the Multiplicity Functor to a raw syntax node.
    pub fn apply_functor(payload: T, prime_index: usize, weight: f64) -> Self {
        Sig {
            ast_payload: payload,
            prime_index,
            weight,
            topological_defect: 0.0, // Initial state, computed during constraint checking
        }
    }
}
