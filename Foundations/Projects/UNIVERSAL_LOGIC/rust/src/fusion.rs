//! Cross-Logic Fusion Operator (⊕) & Typed Interoperability

use crate::algebras::fuzzy::FuzzyLogic;
use crate::algebras::heyting::HeytingElement;
use crate::algebras::quantum::QuantumEffect;

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FusionAlgebra {
    MV,
    Product,
    Godel,
}

pub struct LogicFusionEngine;

impl LogicFusionEngine {
    /// Embed Boolean into [0, 1] fuzzy carrier.
    pub fn embed_classical(b: bool) -> f64 {
        if b {
            1.0
        } else {
            0.0
        }
    }

    /// Embed Heyting element into [0, 1] fuzzy carrier.
    pub fn embed_heyting(h: HeytingElement) -> f64 {
        (h.0 as f64) / 100.0
    }

    /// Embed Quantum Effect trace/expectation into [0, 1] fuzzy carrier.
    pub fn embed_quantum_effect(e: &QuantumEffect) -> f64 {
        ((e.a + e.c) * 0.5).clamp(0.0, 1.0)
    }

    /// Fuse two graded values under chosen target fusion algebra.
    pub fn fuse(x: f64, y: f64, algebra: FusionAlgebra) -> f64 {
        match algebra {
            FusionAlgebra::MV => FuzzyLogic::mv_or(x, y),
            FusionAlgebra::Product => FuzzyLogic::prod_or(x, y),
            FusionAlgebra::Godel => FuzzyLogic::godel_or(x, y),
        }
    }

    /// Lift fuzzy truth value to Quantum Effect scalar matrix: U = u * I.
    pub fn lift_fuzzy_to_quantum_effect(u: f64) -> QuantumEffect {
        let val = u.clamp(0.0, 1.0);
        QuantumEffect::new(val, 0.0, val)
    }
}
