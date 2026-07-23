//! Shared refinement types for Lean↔Rust control-surface contracts.
//!
//! This module defines the minimal contract schema that both the Lean governance
//! layer (`ADR.Governance`) and the Rust enforcement layer (`crates/mirror-dissonance`)
//! can verify. It is intentionally small: extend it only when a new control
//! surface must be provably wired across both layers.

use serde::{Deserialize, Serialize};

/// Status values mirrored from `ADR.ADRStatus` in Lean.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum AdrStatus {
    Proposed = 0,
    Accepted = 1,
    Deprecated = 2,
    Superseded = 3,
}

impl TryFrom<u8> for AdrStatus {
    type Error = ();
    fn try_from(v: u8) -> Result<Self, Self::Error> {
        match v {
            0 => Ok(AdrStatus::Proposed),
            1 => Ok(AdrStatus::Accepted),
            2 => Ok(AdrStatus::Deprecated),
            3 => Ok(AdrStatus::Superseded),
            _ => Err(()),
        }
    }
}

impl From<AdrStatus> for u8 {
    fn from(s: AdrStatus) -> Self {
        s as u8
    }
}

/// A control-surface contract that both Lean and Rust can serialize/deserialize.
/// The Lean side proves invariants over this schema; the Rust side enforces them.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ControlSurfaceContract {
    pub adr_id: u32,
    pub status: AdrStatus,
    pub supersedes: Option<u32>,
    pub links: Vec<String>,
    pub allowed_transitions: Vec<(u8, u8)>,
    pub circuit_breaker: CircuitBreakerState,
}

/// Circuit-breaker states mirrored from `ADR.Dissonance.CircuitBreakerState`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum CircuitBreakerState {
    Closed = 0,
    Open = 1,
    HalfOpen = 2,
}

impl TryFrom<u8> for CircuitBreakerState {
    type Error = ();
    fn try_from(v: u8) -> Result<Self, Self::Error> {
        match v {
            0 => Ok(CircuitBreakerState::Closed),
            1 => Ok(CircuitBreakerState::Open),
            2 => Ok(CircuitBreakerState::HalfOpen),
            _ => Err(()),
        }
    }
}

impl From<CircuitBreakerState> for u8 {
    fn from(s: CircuitBreakerState) -> Self {
        s as u8
    }
}

impl ControlSurfaceContract {
    /// Reject a re-entrant Accepted → Proposed transition.
    pub fn reject_reentrant_acceptance(&self) -> bool {
        !self.allowed_transitions.contains(&(AdrStatus::Accepted as u8, AdrStatus::Proposed as u8))
    }

    /// Verify that a superseding ADR references a strictly smaller ID.
    pub fn supersession_acyclic(&self) -> bool {
        match self.supersedes {
            Some(sid) => sid < self.adr_id,
            None => true,
        }
    }

    /// Accepted ADRs must carry at least one artifact link.
    pub fn accepted_has_links(&self) -> bool {
        if self.status == AdrStatus::Accepted {
            !self.links.is_empty()
        } else {
            true
        }
    }

    /// Full contract validity check (mirrors `ValidADR` in Lean).
    pub fn is_valid(&self) -> bool {
        self.adr_id > 0
            && self.reject_reentrant_acceptance()
            && self.supersession_acyclic()
            && self.accepted_has_links()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn contract_rejects_reentrant_acceptance() {
        let contract = ControlSurfaceContract {
            adr_id: 1,
            status: AdrStatus::Accepted,
            supersedes: None,
            links: vec!["doc".into()],
            allowed_transitions: vec![(0, 1), (1, 2), (1, 3), (2, 3)],
            circuit_breaker: CircuitBreakerState::Closed,
        };
        assert!(contract.reject_reentrant_acceptance());
    }

    #[test]
    fn contract_supersession_acyclic() {
        let contract = ControlSurfaceContract {
            adr_id: 2,
            status: AdrStatus::Accepted,
            supersedes: Some(1),
            links: vec!["doc".into()],
            allowed_transitions: vec![(0, 1), (1, 3)],
            circuit_breaker: CircuitBreakerState::Closed,
        };
        assert!(contract.supersession_acyclic());
    }

    #[test]
    fn contract_accepted_has_links() {
        let mut contract = ControlSurfaceContract {
            adr_id: 3,
            status: AdrStatus::Accepted,
            supersedes: None,
            links: vec![],
            allowed_transitions: vec![(0, 1), (1, 2), (1, 3), (2, 3)],
            circuit_breaker: CircuitBreakerState::Closed,
        };
        assert!(!contract.accepted_has_links());
        contract.links = vec!["link".into()];
        assert!(contract.accepted_has_links());
    }

    #[test]
    fn contract_full_validity() {
        let contract = ControlSurfaceContract {
            adr_id: 4,
            status: AdrStatus::Accepted,
            supersedes: None,
            links: vec!["link".into()],
            allowed_transitions: vec![(0, 1), (1, 2), (1, 3), (2, 3)],
            circuit_breaker: CircuitBreakerState::Closed,
        };
        assert!(contract.is_valid());
    }
}
