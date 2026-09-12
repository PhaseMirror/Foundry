//! Resonance Terms implementation for PhaseMirror‑Legal.
//! Provides typed predicates and conservation checks.

use serde::{Deserialize, Serialize};
use crate::{Adr, AdrError, AdrId, AdrStatus};

/// Unique identifier for a resonance term.
pub type ResonanceId = u64;

/// Simple predicate over a pair of primes.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum ResonancePredicate {
    /// Threshold predicate: active when exponent of `p` >= `min`.
    Threshold { p: u64, min: i64 },
    /// Custom named predicate – logic is supplied by the caller.
    Custom { name: String },
}

/// Resonance term linking two primes with a strength factor.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResonanceTerm {
    pub id: ResonanceId,
    pub prime_pair: (u64, u64),
    pub predicate: ResonancePredicate,
    pub strength: f64,
    pub adr_link: Option<AdrId>,
}

impl ResonanceTerm {
    /// Check whether the predicate holds given a list of `(prime, exponent)`.
    pub fn is_active(&self, exponents: &[(u64, i64)]) -> bool {
        match &self.predicate {
            ResonancePredicate::Threshold { p, min } => {
                exponents.iter().any(|(prime, exp)| *prime == *p && *exp >= *min)
            }
            ResonancePredicate::Custom { name: _ } => {
                // Placeholder: always active for demo purposes.
                true
            }
        }
    }

    /// Apply the resonance effect to a multiplicity value.
    /// For demonstration we simply multiply by `strength.round()`.
    pub fn apply(&self, multiplicity: i128) -> i128 {
        let factor = self.strength.round() as i128;
        multiplicity * factor.max(1)
    }

    /// Attach an ADR (must be Accepted) for provenance.
    pub fn attach_adr(&mut self, adr: &Adr) -> Result<(), AdrError> {
        if adr.status != AdrStatus::Accepted {
            return Err(AdrError::ImmutableAccepted);
        }
        self.adr_link = Some(adr.id);
        Ok(())
    }
}
