//! Core ADR model for PhaseMirror‑Legal.
//! Provides immutable status after acceptance, supersession handling, and traceability.

use serde::{Deserialize, Serialize};
use thiserror::Error;

/// Unique identifier for an ADR.
pub type AdrId = u64;

/// Status of an ADR.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum AdrStatus {
    Proposed,
    Accepted,
    Deprecated,
    Superseded,
}

/// Links to external artifacts (e.g., docs, commits).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ArtifactLink {
    pub url: String,
    pub description: Option<String>,
}

/// Primary ADR struct.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Adr {
    pub id: AdrId,
    pub title: String,
    pub status: AdrStatus,
    pub context: String,
    pub decision: String,
    pub consequences: Vec<String>,
    pub supersedes: Option<AdrId>,
    pub links: Vec<ArtifactLink>,
}

/// Errors that can occur during ADR operations.
#[derive(Debug, Error, PartialEq, Eq)]
pub enum AdrError {
    #[error("cannot modify an accepted ADR unless superseded")]
    ImmutableAccepted,
    #[error("supersession would introduce a cycle")]
    CycleDetected,
    #[error("referenced superseded ADR not found")] 
    SupersededNotFound,
}

impl Adr {
    /// Create a new ADR in the Proposed state.
    pub fn new(id: AdrId, title: impl Into<String>, context: impl Into<String>, decision: impl Into<String>, consequences: Vec<String>, links: Vec<ArtifactLink>) -> Self {
        Self {
            id,
            title: title.into(),
            status: AdrStatus::Proposed,
            context: context.into(),
            decision: decision.into(),
            consequences,
            supersedes: None,
            links,
        }
    }

    /// Transition the ADR to a new status, enforcing invariants.
    pub fn transition(&mut self, new_status: AdrStatus, superseding_id: Option<AdrId>) -> Result<(), AdrError> {
        match (self.status, new_status) {
            // Accepted -> any non‑Accepted allowed only via supersession.
            (AdrStatus::Accepted, AdrStatus::Superseded) => {
                self.status = new_status;
                self.supersedes = superseding_id;
                Ok(())
            }
            // Any state -> Accepted is allowed.
            (_, AdrStatus::Accepted) => {
                self.status = new_status;
                Ok(())
            }
            // Proposed -> Deprecated allowed.
            (AdrStatus::Proposed, AdrStatus::Deprecated) => {
                self.status = new_status;
                Ok(())
            }
            // No other transitions allowed.
            _ => Err(AdrError::ImmutableAccepted),
        }
    }

    /// Verify that the supersession chain is acyclic.
    /// `registry` maps ADR ids to ADRs and is used to walk the chain.
    pub fn validate_acyclic(&self, registry: &std::collections::HashMap<AdrId, Adr>) -> Result<(), AdrError> {
        let mut visited = std::collections::HashSet::new();
        let mut current = self.supersedes;
        while let Some(id) = current {
            if !visited.insert(id) {
                return Err(AdrError::CycleDetected);
            }
            match registry.get(&id) {
                Some(adr) => current = adr.supersedes,
                None => return Err(AdrError::SupersededNotFound),
            }
        }
        Ok(())
    }

    /// Reconstruct the full supersession history for this ADR.
    pub fn history(&self, registry: &std::collections::HashMap<AdrId, Adr>) -> Vec<AdrId> {
        let mut chain = vec![self.id];
        let mut current = self.supersedes;
        while let Some(id) = current {
            chain.push(id);
            current = registry.get(&id).and_then(|adr| adr.supersedes);
        }
        chain
    }
}

pub mod examples;

pub mod pirtm;

pub mod resonance;
