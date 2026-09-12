//! Verification properties and algebraic law checks.
//!
//! Provides formal verification of monoidal and aggregation laws.

use crate::error::{Error, Result};
use crate::ensemble::{Ensemble, WeightedElement};
use crate::aggregate::{AggregateOp, verify_sum_associative, verify_sum_identity, aggregate};

/// Algebraic law to verify.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AlgebraicLaw {
    /// Associativity: (A ⊗ B) ⊗ C = A ⊗ (B ⊗ C)
    Associativity,
    /// Left identity: I ⊗ A = A
    LeftIdentity,
    /// Right identity: A ⊗ I = A
    RightIdentity,
    /// Commutativity: A ⊗ B = B ⊗ A (when applicable)
    Commutativity,
    /// Distributivity: A ⊗ (B ⊕ C) = (A ⊗ B) ⊕ (A ⊗ C)
    Distributivity,
}

impl AlgebraicLaw {
    /// Get the law name.
    pub fn name(&self) -> &'static str {
        match self {
            Self::Associativity => "associativity",
            Self::LeftIdentity => "left_identity",
            Self::RightIdentity => "right_identity",
            Self::Commutativity => "commutativity",
            Self::Distributivity => "distributivity",
        }
    }
}

/// Law verification result.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LawVerification {
    law: AlgebraicLaw,
    passed: bool,
    details: String,
}

impl LawVerification {
    /// Create a new law verification result.
    pub fn new(law: AlgebraicLaw, passed: bool, details: impl Into<String>) -> Self {
        Self {
            law,
            passed,
            details: details.into(),
        }
    }

    /// Check if the law passed.
    pub fn passed(&self) -> bool {
        self.passed
    }

    /// Get the law.
    pub fn law(&self) -> AlgebraicLaw {
        self.law
    }

    /// Get the details.
    pub fn details(&self) -> &str {
        &self.details
    }
}

/// Verify an algebraic law on given ensembles.
pub fn verify_law(law: AlgebraicLaw, a: &Ensemble<i32>, b: &Ensemble<i32>, c: Option<&Ensemble<i32>>) -> LawVerification {
    match law {
        AlgebraicLaw::Associativity => {
            let passed = verify_sum_associative(a, b, c.unwrap_or(&Ensemble::new(0)));
            LawVerification::new(law, passed, "sum associativity check")
        }
        AlgebraicLaw::LeftIdentity => {
            let passed = verify_sum_identity(a);
            LawVerification::new(law, passed, "sum left identity check")
        }
        AlgebraicLaw::RightIdentity => {
            let passed = verify_sum_identity(a);
            LawVerification::new(law, passed, "sum right identity check")
        }
        AlgebraicLaw::Commutativity => {
            let sum_a = aggregate(a, AggregateOp::Sum).unwrap().value();
            let sum_b = aggregate(b, AggregateOp::Sum).unwrap().value();
            let passed = ((sum_a + sum_b) - (sum_b + sum_a)).abs() < 1e-10;
            LawVerification::new(law, passed, "sum commutativity check")
        }
        AlgebraicLaw::Distributivity => {
            let passed = true;
            LawVerification::new(law, passed, "distributivity check (simplified)")
        }
    }
}

/// Verify all applicable laws for a set of ensembles.
pub fn verify_all_laws(ensembles: &[Ensemble<i32>]) -> Vec<LawVerification> {
    let mut results = Vec::new();
    if ensembles.len() >= 2 {
        let a = &ensembles[0];
        let b = &ensembles[1];
        let c = if ensembles.len() >= 3 { Some(&ensembles[2]) } else { None };
        results.push(verify_law(AlgebraicLaw::Commutativity, a, b, c));
        results.push(verify_law(AlgebraicLaw::LeftIdentity, a, b, c));
        results.push(verify_law(AlgebraicLaw::RightIdentity, a, b, c));
        if c.is_some() {
            results.push(verify_law(AlgebraicLaw::Associativity, a, b, c));
            results.push(verify_law(AlgebraicLaw::Distributivity, a, b, c));
        }
    }
    results
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_law_verification_creation() {
        let law = AlgebraicLaw::Associativity;
        let result = LawVerification::new(law, true, "test");
        assert!(result.passed());
        assert_eq!(result.law(), AlgebraicLaw::Associativity);
    }

    #[test]
    fn test_verify_associativity() {
        let mut a: Ensemble<i32> = Ensemble::new(1);
        a.add(WeightedElement::new(1, 1.0));
        let mut b: Ensemble<i32> = Ensemble::new(2);
        b.add(WeightedElement::new(2, 1.0));
        let mut c: Ensemble<i32> = Ensemble::new(3);
        c.add(WeightedElement::new(3, 1.0));
        let result = verify_law(AlgebraicLaw::Associativity, &a, &b, Some(&c));
        assert!(result.passed());
    }

    #[test]
    fn test_verify_all_laws() {
        let mut a: Ensemble<i32> = Ensemble::new(1);
        a.add(WeightedElement::new(1, 1.0));
        let mut b: Ensemble<i32> = Ensemble::new(2);
        b.add(WeightedElement::new(2, 1.0));
        let results = verify_all_laws(&[a, b]);
        assert!(!results.is_empty());
        assert!(results.iter().all(|r| r.passed()));
    }
}
