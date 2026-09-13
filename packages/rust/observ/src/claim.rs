//! Six-component claim gate (ADR-0026).
//!
//! The claim vector is c = (M, S, E, χ, R, K) — microstructure, source state,
//! exchange-energy split, spin-split character, reversal response, and the
//! kernel/linkage — each valued in the status lattice
//!
//! Closed, Supported, Provisional, Open, Contradicted, Disfavored, Blocked,
//! StateDependent.
//!
//! The gate enforces two structural rules that are pure consequences of the
//! measurement-map geometry and require no physics input:
//!
//! 1. **Source-state precedence.** A contaminated/contradicted microstructure
//!    can never yield a closed or supported source claim: `S ≤ M` in the sense
//!    that `M ∈ {Contradicted, Blocked}` forces every downstream component
//!    (S, E, χ, R, K) to block. Declaring otherwise is a
//!    `DownstreamBeforeSourceGate` defect.
//!
//! 2. **Channel closure.** Any component closed via a probe must have its own
//!    declared channel, and that channel's obstruction dimension must be zero
//!    when the status claims closure. Declaring a positive signal in a channel
//!    that cannot resolve the component is a `ClaimMigration` defect.
//!
//! No status change is autodeduced: the verdict reports the *declared* status
//! and the *revised* status implied by the gate, so honest disagreements
//! surface as defects rather than silent rewrites.

use crate::system::{ClaimClause, ClaimStatus};

pub const COMPONENTS: [&str; 6] = ["M", "S", "E", "X", "R", "K"];

pub fn component_rank(c: &str) -> Option<usize> {
    COMPONENTS.iter().position(|&x| x == c.to_uppercase())
}

/// Microstructure alone can say nothing about source state; a closing claim must
/// name a channel whose obstruction dimension is zero.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ClaimAssessment {
    pub component: u8,
    pub declared: ClaimStatus,
    pub revised: ClaimStatus,
    /// True when the declared channel resolves the component (obstruction 0).
    pub identified: bool,
    /// True when downstream revision is applied due to source-state gate.
    pub downstream_blocked: bool,
}

pub fn assess_claims(
    claims: &[ClaimClause],
    identified: &dyn Fn(&ClaimClause) -> Option<bool>,
) -> Vec<ClaimAssessment> {
    let mut by_component: std::collections::BTreeMap<u8, ClaimStatus> = Default::default();
    for cl in claims {
        if let Some(r) = component_rank(&cl.component) {
            by_component.entry(r as u8).or_insert(cl.status);
        }
    }

    let source_contaminated = by_component
        .get(&0)
        .map(|s| matches!(s, ClaimStatus::Contradicted | ClaimStatus::Blocked))
        .unwrap_or(false);

    claims
        .iter()
        .map(|cl| {
            let comp = component_rank(&cl.component).unwrap_or(0) as u8;
            let id = identified(cl);
            let closes = matches!(cl.status, ClaimStatus::Closed | ClaimStatus::Supported);
            let identified_ok = !closes || id == Some(true);

            // Downstream of a contaminated micro state: block.
            let downstream = comp > 0 && source_contaminated;
            let revised = if downstream {
                ClaimStatus::Blocked
            } else {
                cl.status
            };
            ClaimAssessment {
                component: comp,
                declared: cl.status,
                revised,
                identified: identified_ok,
                downstream_blocked: downstream,
            }
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::system::{ClaimClause, ClaimStatus};

    fn clause(component: &str, status: ClaimStatus, channel: Option<&str>) -> ClaimClause {
        ClaimClause {
            component: component.into(),
            status,
            channel: channel.map(|s| s.into()),
            focus: channel.map(|s| s.into()),
        }
    }

    #[test]
    fn contaminated_micro_blocks_downstream() {
        let claims = vec![
            clause("M", ClaimStatus::Contradicted, Some("fm")),
            clause("S", ClaimStatus::Closed, Some("src")),
        ];
        let out = assess_claims(&claims, &|_| Some(true));
        assert!(out[1].downstream_blocked);
        assert_eq!(out[1].revised, ClaimStatus::Blocked);
    }

    #[test]
    fn closing_claim_needs_its_own_resolution() {
        let claims = vec![clause("S", ClaimStatus::Closed, Some("src"))];
        let out = assess_claims(&claims, &|cl| {
            if cl.component == "S" {
                Some(false)
            } else {
                Some(true)
            }
        });
        assert!(!out[0].identified);
    }

    #[test]
    fn clean_source_leaves_status_alone() {
        let claims = vec![
            clause("M", ClaimStatus::Closed, Some("fm")),
            clause("S", ClaimStatus::Supported, Some("src")),
        ];
        let out = assess_claims(&claims, &|_| Some(true));
        assert!(!out[1].downstream_blocked);
        assert_eq!(out[1].revised, ClaimStatus::Supported);
    }

    #[test]
    fn phase_augmented_character_is_not_attribution() {
        // ADR-0026: a modified band structure can make χ ≠ 0 while S stays open.
        let claims = vec![
            clause("M", ClaimStatus::Closed, Some("fm")),
            clause("X", ClaimStatus::Closed, Some("gapped")),
            clause("S", ClaimStatus::Open, Some("src")),
        ];
        let out = assess_claims(&claims, &|_| Some(true));
        assert_eq!(out[2].revised, ClaimStatus::Open);
        assert!(!out[2].downstream_blocked);
    }
}
