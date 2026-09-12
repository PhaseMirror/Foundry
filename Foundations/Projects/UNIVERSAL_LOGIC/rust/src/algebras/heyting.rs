//! Heyting Algebra / Intuitionistic Logic Module

/// Finite Heyting lattice element representation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct HeytingElement(pub u8);

pub struct HeytingLogic;

impl HeytingLogic {
    pub const BOTTOM: HeytingElement = HeytingElement(0);
    pub const TOP: HeytingElement = HeytingElement(100);

    pub fn meet(a: HeytingElement, b: HeytingElement) -> HeytingElement {
        HeytingElement(a.0.min(b.0))
    }

    pub fn join(a: HeytingElement, b: HeytingElement) -> HeytingElement {
        HeytingElement(a.0.max(b.0))
    }

    /// Relative pseudo-complement: a => b is greatest c such that a ∧ c ≤ b.
    pub fn implies(a: HeytingElement, b: HeytingElement) -> HeytingElement {
        if a.0 <= b.0 {
            Self::TOP
        } else {
            b
        }
    }

    /// Intuitionistic negation: ¬a = (a => 0).
    pub fn not(a: HeytingElement) -> HeytingElement {
        Self::implies(a, Self::BOTTOM)
    }
}
