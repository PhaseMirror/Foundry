//! Example ADRs used by the test harness.

use crate::{Adr, AdrId, AdrStatus, ArtifactLink};

/// Returns a vector of three realistic ADR examples.
pub fn example_adrs() -> Vec<Adr> {
    vec![
        Adr {
            id: 1,
            title: "Use Rust for ADR framework".into(),
            status: AdrStatus::Accepted,
            context: "PhaseMirror‑Legal mandates Rust for all legal logic".into(),
            decision: "Implement ADR handling in Rust".into(),
            consequences: vec!["Zero drift enforced".into()],
            supersedes: None,
            links: vec![ArtifactLink { url: "https://github.com/PhaseMirror/legal".into(), description: Some("Repo".into()) }],
        },
        Adr {
            id: 2,
            title: "Deprecate old Python ADR scaffold".into(),
            status: AdrStatus::Deprecated,
            context: "Legacy Python scaffold no longer maintained".into(),
            decision: "Mark Python ADR scaffold as deprecated".into(),
            consequences: vec!["Developers migrate to Rust".into()],
            supersedes: Some(1),
            links: vec![],
        },
        Adr {
            id: 3,
            title: "Add audit‑trail feature".into(),
            status: AdrStatus::Proposed,
            context: "Need explicit audit trail for each ADR".into(),
            decision: "Introduce a linked‑list of supersessions".into(),
            consequences: vec!["Traceability guaranteed".into()],
            supersedes: None,
            links: vec![],
        },
    ]
}
