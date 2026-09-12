//! ADR registry — the collection of all ADRs with global validation.
//!
//! The registry enforces:
//! - Every supersession reference points to an existing ADR
//! - No circular supersession chains anywhere in the registry
//! - All `Accepted` ADRs have a reconstructible history

use super::{Adr, AdrError, AdrId};
use std::collections::HashMap;

/// Registry of all ADRs.
///
/// `AdrRegistry` owns the authoritative set of ADRs and provides
/// methods to validate global invariants.
#[derive(Debug, Clone, Default)]
pub struct AdrRegistry {
    adrs: HashMap<AdrId, Adr>,
}

impl AdrRegistry {
    /// Create an empty registry.
    pub fn new() -> Self {
        Self::default()
    }

    /// Insert an ADR.  Replaces any existing ADR with the same ID.
    pub fn insert(&mut self, adr: Adr) {
        self.adrs.insert(adr.id, adr);
    }

    /// Retrieve an ADR by ID.
    pub fn get(&self, id: AdrId) -> Option<&Adr> {
        self.adrs.get(&id)
    }

    /// Mutable access to an ADR by ID.
    pub fn get_mut(&mut self, id: AdrId) -> Option<&mut Adr> {
        self.adrs.get_mut(&id)
    }

    /// Remove an ADR by ID.
    pub fn remove(&mut self, id: AdrId) -> Option<Adr> {
        self.adrs.remove(&id)
    }

    /// Validate that the entire registry is acyclic.
    ///
    /// Returns the first error found, or `Ok(())` if all chains are valid.
    pub fn validate_acyclic(&self) -> Result<(), AdrError> {
        for adr in self.adrs.values() {
            adr.validate_acyclic(&self.adrs)?;
        }
        Ok(())
    }

    /// Collect all `Accepted` ADRs and verify their histories are reconstructible.
    pub fn validate_traceability(&self) -> Result<Vec<AdrId>, AdrError> {
        let mut accepted_ids = Vec::new();
        for adr in self.adrs.values() {
            if adr.status == super::AdrStatus::Accepted {
                let history = adr.history(&self.adrs);
                // Reconstructibility: every ID in the history must exist.
                for &hid in &history {
                    if !self.adrs.contains_key(&hid) {
                        return Err(AdrError::SupersededNotFound);
                    }
                }
                accepted_ids.push(adr.id);
            }
        }
        Ok(accepted_ids)
    }

    /// Verify that consequences are entailed by decision + context for all ADRs.
    ///
    /// The entailment check is intentionally simple: each consequence string
    /// must be a substring of the concatenation of decision and context.
    /// Replace with a full embedded logic DSL in production.
    pub fn validate_consequence_entailment(&self) -> Result<(), AdrError> {
        for adr in self.adrs.values() {
            let corpus = format!("{} {}", adr.decision, adr.context);
            for consequence in &adr.consequences {
                if !consequence.is_empty() && !corpus.contains(consequence) {
                    return Err(AdrError::EntailmentFailed);
                }
            }
        }
        Ok(())
    }

    /// Run all global invariants and return the first failure.
    pub fn validate_all(&self) -> Result<(), AdrError> {
        self.validate_acyclic()?;
        self.validate_traceability()?;
        self.validate_consequence_entailment()?;
        Ok(())
    }

    /// Iterate over all ADRs.
    pub fn iter(&self) -> impl Iterator<Item = (&AdrId, &Adr)> {
        self.adrs.iter()
    }

    /// Number of ADRs in the registry.
    pub fn len(&self) -> usize {
        self.adrs.len()
    }

    /// Whether the registry is empty.
    pub fn is_empty(&self) -> bool {
        self.adrs.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_registry_valid() {
        let reg = AdrRegistry::new();
        assert!(reg.validate_all().is_ok());
    }

    #[test]
    fn accepted_traceability() {
        let mut reg = AdrRegistry::new();
        let adr = Adr::new(1, "T", "C", "D", vec![], vec![]).unwrap();
        reg.insert(adr);
        assert!(reg.validate_traceability().is_ok());
    }
}
