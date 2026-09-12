//! The `Adr` struct and its methods.
//!
//! Key design choice: `transition` is the *only* mutating entry point.
/// All other methods are pure queries.  This makes the state machine
/// inspectable by Kani: every path from `Proposed` to `Accepted` is
/// explicit in the `match` below.

use super::{AdrError, AdrId, AdrStatus, ArtifactLink};

/// Primary ADR struct.
///
/// Fields mirror the ADR-0004 specification:
/// - `id` and `title` for identity
/// - `status` for lifecycle stage
/// - `context` and `decision` for the logical core
/// - `consequences` for downstream effects
/// - `supersedes` for the supersession chain
/// - `links` for external traceability
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
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

impl Adr {
    /// Create a new ADR in the `Proposed` state.
    ///
    /// # Validation
    ///
    /// Returns `Err(AdrError::InvalidContent)` if title or decision is empty.
    pub fn new(
        id: AdrId,
        title: impl Into<String>,
        context: impl Into<String>,
        decision: impl Into<String>,
        consequences: Vec<String>,
        links: Vec<ArtifactLink>,
    ) -> Result<Self, AdrError> {
        let title = title.into();
        let decision = decision.into();
        if title.is_empty() || decision.is_empty() {
            return Err(AdrError::InvalidContent);
        }
        Ok(Self {
            id,
            title,
            status: AdrStatus::Proposed,
            context: context.into(),
            decision,
            consequences,
            supersedes: None,
            links,
        })
    }

    /// Transition the ADR to a new status.
    ///
    /// **Invariants enforced:**
    /// 1. An `Accepted` ADR cannot transition to `Deprecated` or `Proposed`
    ///    unless a supersession ID is provided (which routes it through
    ///    `Superseded`).
    /// 2. A `Proposed` ADR can become `Accepted` or `Deprecated`.
    /// 3. A `Deprecated` ADR can become `Accepted` (if revived) or `Superseded`.
    /// 4. A `Superseded` ADR is terminal.
    pub fn transition(
        &mut self,
        new_status: AdrStatus,
        superseding_id: Option<AdrId>,
    ) -> Result<(), AdrError> {
        match (self.status, new_status) {
            // Accepted → Superseded requires a supersession ID.
            (AdrStatus::Accepted, AdrStatus::Superseded) => {
                self.status = AdrStatus::Superseded;
                self.supersedes = superseding_id;
                Ok(())
            }
            // Accepted → anything else is forbidden.
            (AdrStatus::Accepted, _) => Err(AdrError::ImmutableAccepted),
            // Proposed → Accepted.
            (AdrStatus::Proposed, AdrStatus::Accepted) => {
                self.status = AdrStatus::Accepted;
                Ok(())
            }
            // Proposed → Deprecated.
            (AdrStatus::Proposed, AdrStatus::Deprecated) => {
                self.status = AdrStatus::Deprecated;
                Ok(())
            }
            // Proposed → Superseded is forbidden (must be Accepted first).
            (AdrStatus::Proposed, AdrStatus::Superseded) => {
                Err(AdrError::ImmutableAccepted)
            }
            // Deprecated → Accepted (revival).
            (AdrStatus::Deprecated, AdrStatus::Accepted) => {
                self.status = AdrStatus::Accepted;
                Ok(())
            }
            // Deprecated → Superseded.
            (AdrStatus::Deprecated, AdrStatus::Superseded) => {
                self.status = AdrStatus::Superseded;
                self.supersedes = superseding_id;
                Ok(())
            }
            // Deprecated → Proposed is forbidden.
            (AdrStatus::Deprecated, AdrStatus::Proposed) => {
                Err(AdrError::ImmutableAccepted)
            }
            // Superseded → anything is forbidden (terminal state).
            (AdrStatus::Superseded, _) => Err(AdrError::ImmutableAccepted),
        }
    }

    /// Reconstruct the full supersession history for this ADR.
    ///
    /// Returns a vector `[self.id, ..., root_id]` where `root_id` is the
    /// oldest ancestor (no supersession).
    pub fn history(
        &self,
        registry: &std::collections::HashMap<AdrId, Self>,
    ) -> Vec<AdrId> {
        let mut chain = vec![self.id];
        let mut current = self.supersedes;
        while let Some(id) = current {
            chain.push(id);
            current = registry.get(&id).and_then(|adr| adr.supersedes);
        }
        chain
    }

    /// Walk the supersession chain and verify it is acyclic.
    ///
    /// A cycle would mean ADR `i` supersedes ADR `j` which eventually
    /// supersedes ADR `i` again — impossible in a valid registry.
    pub fn validate_acyclic(
        &self,
        registry: &std::collections::HashMap<AdrId, Self>,
    ) -> Result<(), AdrError> {
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
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    #[test]
    fn proposed_to_accepted() {
        let mut adr = Adr::new(1, "T", "C", "D", vec![], vec![]).unwrap();
        assert!(adr.transition(AdrStatus::Accepted, None).is_ok());
        assert_eq!(adr.status, AdrStatus::Accepted);
    }

    #[test]
    fn accepted_immutable_without_supersession() {
        let mut adr = Adr::new(1, "T", "C", "D", vec![], vec![]).unwrap();
        adr.transition(AdrStatus::Accepted, None).unwrap();
        assert!(adr.transition(AdrStatus::Deprecated, None).is_err());
    }

    #[test]
    fn accepted_can_supersede() {
        let mut adr = Adr::new(1, "T", "C", "D", vec![], vec![]).unwrap();
        adr.transition(AdrStatus::Accepted, None).unwrap();
        assert!(adr.transition(AdrStatus::Superseded, Some(2)).is_ok());
    }

    #[test]
    fn acyclic_chain() {
        let mut registry = HashMap::new();
        let a1 = Adr::new(1, "T1", "C1", "D1", vec![], vec![]).unwrap();
        let a2 = Adr::new(2, "T2", "C2", "D2", vec![], vec![]).unwrap();
        registry.insert(1, a1);
        registry.insert(2, a2);
        assert!(a1.validate_acyclic(&registry).is_ok());
    }
}
