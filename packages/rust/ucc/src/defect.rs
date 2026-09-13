//! Named, English-expressible defects (Δ) and their fixed-point metrics.
//!
//! Each defect is a named, actionable diagnosis: "Δ named in English a node can
//! act on" (ADR-0014 §Product). `metric` is the fixed-point norm ‖Δ‖ in the same
//! scaling as [`crmf::failgate`] so `crmf::is_associator_defect` applies.

use serde::{Deserialize, Serialize};

/// Δ — the named defect classes emitted by the L0 gate.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize, Hash)]
#[serde(rename_all = "snake_case")]
pub enum DefectCode {
    /// An object identity is not a prime number.
    IdentityIrreducible,
    /// Two objects share the same prime identity.
    IdentityUnique,
    /// A relation references an identity outside X (forbidden prime channel).
    RelationDangling,
    /// The surplus ledger μ keys an identity not declared in X.
    MultiplicityKeyUnknown,
    /// The endomorphism F is malformed (unknown kind, or iterate == 0).
    EndomorphismUnlawful,
    /// The coherence anchor α does not match the composition law.
    CoherenceAnchor,
    /// Composition would decrease a surplus exponent below its carried base.
    MonotonicityBreach,
    /// The scaled associator norm ‖Δ‖ exceeds the tolerance.
    AssociatorDefect,
    /// The scaled envelope Λ_m fails contractivity, or recursion escalated.
    ExpansiveTransition,
    /// A lawful composition overflows the integer envelope.
    ArithmeticOverflow,
}

impl DefectCode {
    /// English name a node can act on.
    pub const fn english(self) -> &'static str {
        match self {
            DefectCode::IdentityIrreducible => {
                "identity is not a prime number; rename the object to an irreducible prime"
            }
            DefectCode::IdentityUnique => {
                "duplicate identity: two objects claim the same prime index"
            }
            DefectCode::RelationDangling => {
                "dangling relation: a composition references an identity outside the declared surface"
            }
            DefectCode::MultiplicityKeyUnknown => {
                "unknown multiplicity key: the surplus ledger indexes an undeclared identity"
            }
            DefectCode::EndomorphismUnlawful => {
                "unlawful endomorphism: the transform kind is unknown or its iterate is zero"
            }
            DefectCode::CoherenceAnchor => {
                "coherence anchor violated: alpha is not the identity of the declared composition law"
            }
            DefectCode::MonotonicityBreach => {
                "monotonicity breach: a surplus exponent would decrease below its carried base"
            }
            DefectCode::AssociatorDefect => {
                "associator defect: the two association orders of the composition disagree beyond tolerance"
            }
            DefectCode::ExpansiveTransition => {
                "expansive transition: the spectral envelope exceeds contractivity or recursion escalated"
            }
            DefectCode::ArithmeticOverflow => {
                "arithmetic overflow: the lawful composition exceeds the integer envelope"
            }
        }
    }

    /// The lever action paired with this defect.
    pub const fn lever_action(self) -> &'static str {
        match self {
            DefectCode::IdentityIrreducible => "re-key the object's prime to an irreducible prime",
            DefectCode::IdentityUnique => "drop one of the colliding objects",
            DefectCode::RelationDangling => {
                "add the endpoint to the declared surface or drop the relation"
            }
            DefectCode::MultiplicityKeyUnknown => {
                "align the surplus ledger keys to the declared surface"
            }
            DefectCode::EndomorphismUnlawful => {
                "correct the endomorphism kind and set iterate >= 1"
            }
            DefectCode::CoherenceAnchor => {
                "set alpha to the identity of the declared composition law"
            }
            DefectCode::MonotonicityBreach => "carry the full surplus base before composing",
            DefectCode::AssociatorDefect => "split the composition into lawful association orders",
            DefectCode::ExpansiveTransition => {
                "compress the surplus envelope below the contractive ceiling"
            }
            DefectCode::ArithmeticOverflow => {
                "reduce the system size below the integer envelope limit"
            }
        }
    }
}

/// A concrete, named defect of one call.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct UccDefect {
    pub code: DefectCode,
    /// Δ named in English a node can act on.
    pub english: String,
    /// Affected prime identities.
    pub nodes: Vec<u64>,
    /// Fixed-point bound ‖Δ‖ in the failgate scaling.
    pub metric: u64,
}

impl UccDefect {
    pub fn new(code: DefectCode, metric: u64) -> Self {
        UccDefect {
            code,
            english: code.english().to_string(),
            nodes: Vec::new(),
            metric,
        }
    }

    pub fn with_nodes(mut self, nodes: Vec<u64>) -> Self {
        self.nodes = nodes;
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_defect_names_english() {
        for code in [
            DefectCode::IdentityIrreducible,
            DefectCode::IdentityUnique,
            DefectCode::RelationDangling,
            DefectCode::MultiplicityKeyUnknown,
            DefectCode::EndomorphismUnlawful,
            DefectCode::CoherenceAnchor,
            DefectCode::MonotonicityBreach,
            DefectCode::AssociatorDefect,
            DefectCode::ExpansiveTransition,
            DefectCode::ArithmeticOverflow,
        ] {
            assert!(!code.english().is_empty());
            assert!(!code.lever_action().is_empty());
        }
    }
}
