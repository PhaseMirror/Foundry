//! Core ADR definitions and invariants enforced via Rust/Kani.

pub mod status;
pub mod link;

use status::ADRStatus;
pub use status::ADRStatus; // Re-export for external use
use link::ArtifactLink;
use std::collections::HashSet;

/// Unique identifier for an ADR.
pub type ADRId = u32;

/// Primary ADR structure.
#[derive(Debug, Clone)]
pub struct ADR {
    pub id: ADRId,
    pub title: String,
    pub status: ADRStatus,
    pub context: String,
    pub decision: String,
    pub consequences: Vec<String>,
    pub supersedes: Option<ADRId>,
    pub links: Vec<ArtifactLink>,
}

impl ADR {
    /// Create a new proposed ADR.
    pub fn new(id: ADRId, title: &str, context: &str, decision: &str, consequences: Vec<String>) -> Self {
        ADR {
            id,
            title: title.to_string(),
            status: ADRStatus::Proposed,
            context: context.to_string(),
            decision: decision.to_string(),
            consequences,
            supersedes: None,
            links: Vec::new(),
        }
    }

    /// Accept the ADR. Cannot accept if already superseded.
    pub fn accept(&mut self) {
        assert!(self.status == ADRStatus::Proposed, "Only proposed ADRs may be accepted");
        self.status = ADRStatus::Accepted;
    }

    /// Deprecate the ADR.
    pub fn deprecate(&mut self) {
        self.status = ADRStatus::Deprecated;
    }

    /// Supersede this ADR with a new one.
    pub fn supersede(&mut self, new_id: ADRId) {
        self.supersedes = Some(new_id);
        self.status = ADRStatus::Superseded;
    }
}

/// Verify invariants using Kani.
#[cfg(kani)]
mod invariants {
    use super::*;
    use kani::proof;

    /// Once an ADR is Accepted, its status cannot change unless superseded.
    #[proof]
    pub fn immutable_after_accept(mut adr: ADR, new_status: ADRStatus) {
        adr.accept();
        if let Some(_sup) = adr.supersedes {
            // superseded case allowed – status can change via supersede.
        } else {
            // Must remain Accepted.
            assert!(adr.status == ADRStatus::Accepted);
            // Attempting to change status should fail – Kani treats panic as verification failure.
            assert!(new_status == ADRStatus::Accepted);
        }
    }

    /// No circular supersession chains.
    #[proof]
    pub fn no_circular_supersession(adr1: ADR, adr2: ADR) {
        // If adr1 supersedes adr2, adr2 must not supersede adr1.
        if let Some(id1) = adr1.supersedes {
            if let Some(id2) = adr2.supersedes {
                assert!(id1 != adr2.id || id2 != adr1.id);
            }
        }
    }
}

