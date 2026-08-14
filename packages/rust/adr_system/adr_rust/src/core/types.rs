//! Core type definitions for ADR governance.
//!
//! These types model the minimal state required to enforce the ADR-0004 invariants:
//! - status immutability after acceptance
//! - acyclic supersession chains
//! - reconstructible history

use serde::{Deserialize, Serialize};
use thiserror::Error;

/// Unique identifier for an ADR.
pub type AdrId = u64;

/// Status of an ADR.
///
/// The state machine is:
/// ```text
/// Proposed ──► Accepted ──► Superseded
///    │                       ▲
///    └──► Deprecated         │
///                            │
///                     (via supersession)
/// ```
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum AdrStatus {
    /// Draft stage; subject to modification.
    Proposed,
    /// Ratified and immutable unless explicitly superseded.
    Accepted,
    /// Withdrawn while supersession is being prepared.
    Deprecated,
    /// Overturned by a later ADR.
    Superseded,
}

/// Link to an external artifact (document, commit, issue, etc.).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ArtifactLink {
    pub url: String,
    pub description: Option<String>,
}

/// Errors that can occur during ADR state transitions or validation.
#[derive(Debug, Error, PartialEq, Eq)]
pub enum AdrError {
    #[error("cannot modify an accepted ADR unless superseded by a later ADR")]
    ImmutableAccepted,
    #[error("supersession chain contains a cycle")]
    CycleDetected,
    #[error("referenced superseding ADR not found in registry")]
    SupersededNotFound,
    #[error("consequence not entailed by decision and context")]
    EntailmentFailed,
    #[error("ADRs must have a non-empty title and decision")]
    InvalidContent,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn status_equality() {
        assert_eq!(AdrStatus::Proposed, AdrStatus::Proposed);
        assert_ne!(AdrStatus::Proposed, AdrStatus::Accepted);
    }

    #[test]
    fn adr_id_hash() {
        use std::collections::HashSet;
        let mut set = HashSet::new();
        set.insert(1);
        set.insert(1);
        assert_eq!(set.len(), 1);
    }
}
