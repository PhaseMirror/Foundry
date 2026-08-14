//! Example ADRs used by integration tests and proof harnesses.
//!
//! These three ADRs form a realistic supersession chain and exercise all
//! governance invariants defined in ADR-0004.

use crate::core::{Adr, AdrId, AdrStatus, ArtifactLink};

/// Returns a vector of three realistic ADR examples forming a supersession chain.
pub fn example_adrs() -> Vec<Adr> {
    vec![
        Adr {
            id: 1,
            title: "Adopt Rust for ADR governance framework".into(),
            status: AdrStatus::Accepted,
            context: "PhaseMirror‑Legal mandates Rust for all legal logic and governance primitives due to memory safety and formal verification support via Kani.".into(),
            decision: "Implement the ADR governance framework in Rust using dependent types and model checking.".into(),
            consequences: vec![
                "Zero‑cost abstractions enforced by the type system".into(),
                "Kani model checking replaces informal review".into(),
            ],
            supersedes: None,
            links: vec![ArtifactLink {
                url: "https://github.com/PhaseMirror/legal/adr/0001".into(),
                description: Some("GitHub issue".into()),
            }],
        },
        Adr {
            id: 2,
            title: "Deprecate Python ADR scaffold".into(),
            status: AdrStatus::Superseded,
            context: "The legacy Python scaffold lacks static verification and cannot enforce the immutability invariants required by ADR‑0004.".into(),
            decision: "Mark the Python ADR scaffold as deprecated and migrate all active work to the Rust implementation.".into(),
            consequences: vec![
                "Developers must use the Rust scaffold for new ADRs".into(),
                "Historical Python ADRs are archived but immutable".into(),
            ],
            supersedes: Some(1),
            links: vec![],
        },
        Adr {
            id: 3,
            title: "Add Kani-verified audit trail to ADR registry".into(),
            status: AdrStatus::Proposed,
            context: "Regulatory compliance requires an append-only audit trail with reconstructible histories for every accepted ADR.".into(),
            decision: "Introduce a linked list of supersessions with Kani-verified acyclicity and traceability guarantees.".into(),
            consequences: vec![
                "Every accepted ADR has a machine-checked history".into(),
                "Circular supersession is impossible by construction".into(),
            ],
            supersedes: None,
            links: vec![ArtifactLink {
                url: "https://github.com/PhaseMirror/legal/adr/0003".into(),
                description: Some("Design doc".into()),
            }],
        },
    ]
}

/// Returns the ADR registry populated with the example ADRs.
pub fn example_registry() -> crate::core::AdrRegistry {
    let mut reg = crate::core::AdrRegistry::new();
    for adr in example_adrs() {
        reg.insert(adr);
    }
    reg
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn examples_are_valid() {
        let reg = example_registry();
        assert!(reg.validate_all().is_ok());
    }

    #[test]
    fn supersession_chain() {
        let reg = example_registry();
        let adr2 = reg.get(2).unwrap();
        let history = adr2.history(&reg.adrs_iter_clone());
        assert_eq!(history, vec![2, 1]);
    }
}
