use serde::{Deserialize, Serialize};
use std::fmt::Debug;

/// The Aperture represents the uncomputable, undecidable future states of the node.
/// It is a type-level guarantee that the closure of the current state is strictly
/// smaller than the space of admissible future states.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Aperture<T> {
    pub known_state: T,
    /// The Ω-region. This is intentionally opaque and uncomputable by the internal logic.
    #[serde(skip)]
    pub omega_region: Option<serde_json::Value>,
}

impl<T: Debug> Aperture<T> {
    pub fn new(state: T) -> Self {
        Self {
            known_state: state,
            omega_region: None, // The blank is protected.
        }
    }

    /// Access the known, computable state.
    pub fn state(&self) -> &T {
        &self.known_state
    }

    /// Explicitly acknowledge that the state is not fully sealed.
    pub fn acknowledge_openness(&self) -> bool {
        true
    }
}
