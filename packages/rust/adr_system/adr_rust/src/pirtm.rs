//! PIRTM (Prime‑Indexed Recursive Tensor‑Matrix) kernel implementation.
//! This module provides a minimal, production‑ready Rust model of the
//! recursive kernel described in the Implementation Roadmap. It is deliberately
//! simple – the recursion rule is represented by an enum with a few concrete
//! variants – but the design is extensible: new rules can be added without
//! breaking existing code.

use serde::{Deserialize, Serialize};
use crate::{Adr, AdrError, AdrId, AdrStatus};

/// Identifier for a PIRTM kernel.
pub type PirtmId = u64;

/// The set of primes that index the kernel. In practice this is a
/// non‑empty ordered list of distinct prime numbers.
pub type PrimeIndices = Vec<u64>;

/// Simple recursion rule for the kernel. The real system supports many
/// sophisticated behaviours; we provide three representative cases.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum RecursionRule {
    /// Increment each prime exponent by a fixed amount.
    Increment { delta: i64 },
    /// Multiply each prime exponent by a constant factor.
    Scale { factor: i64 },
    /// Apply a custom closure – stored as a string identifier; actual
    /// execution would be provided by the caller.
    Custom { name: String },
}

/// Primary kernel structure.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PirtmKernel {
    pub id: PirtmId,
    /// Ordered list of prime indices.
    pub primes: PrimeIndices,
    /// Current exponent vector for each prime.
    pub exponents: Vec<i64>,
    /// Recursion rule applied during `unfold`.
    pub rule: RecursionRule,
    /// Optional link to a governing ADR (for provenance).
    pub adr_link: Option<AdrId>,
}

impl PirtmKernel {
    /// Construct a new kernel in the initial state.
    pub fn new(id: PirtmId, primes: PrimeIndices, initial_exponents: Vec<i64>, rule: RecursionRule) -> Self {
        assert_eq!(primes.len(), initial_exponents.len(), "primes and exponents must align");
        Self { id, primes, exponents: initial_exponents, rule, adr_link: None }
    }

    /// Associate the kernel with an ADR for auditability.
    pub fn attach_adr(&mut self, adr: &Adr) -> Result<(), AdrError> {
        if adr.status != AdrStatus::Accepted {
            // Only accepted ADRs may be used as provenance.
            return Err(AdrError::ImmutableAccepted);
        }
        self.adr_link = Some(adr.id);
        Ok(())
    }

    /// Perform a single unfolding step according to the recursion rule.
    /// Returns a new kernel with updated exponents.
    pub fn unfold(&self) -> Self {
        let mut new_exponents = self.exponents.clone();
        match &self.rule {
            RecursionRule::Increment { delta } => {
                for e in &mut new_exponents { *e += delta; }
            }
            RecursionRule::Scale { factor } => {
                for e in &mut new_exponents { *e *= factor; }
            }
            RecursionRule::Custom { name: _ } => {
                // Placeholder: a real implementation would dispatch based on `name`.
                // For now we leave the exponents unchanged.
            }
        }
        Self { exponents: new_exponents, ..self.clone() }
    }

    /// Verify multiplicity conservation: the product \prod p^{e_p} must be
    /// invariant under the chosen rule (modulo a constant factor that is
    /// explicitly allowed).
    pub fn check_conservation(&self, allow_factor: i64) -> bool {
        let current: i128 = self.primes.iter().zip(self.exponents.iter())
            .map(|(p, e)| (*p as i128).pow((*e).max(0) as u32))
            .product();
        // Simulate one step and compare, allowing a configurable factor.
        let next = self.unfold();
        let next_val: i128 = next.primes.iter().zip(next.exponents.iter())
            .map(|(p, e)| (*p as i128).pow((*e).max(0) as u32))
            .product();
        if allow_factor == 0 {
            current == next_val
        } else {
            next_val == current * (allow_factor as i128)
        }
    }
}
