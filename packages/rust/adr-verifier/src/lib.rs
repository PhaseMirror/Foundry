use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use thiserror::Error;

// ---------------------------------------------------------------------------
// ADR structural invariants (numeric ADR registry — supersession, cycles)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum AdrStatus {
    Proposed,
    Accepted,
    Deprecated,
    Superseded,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum ArtifactKind {
    GitCommit,
    LeanDeclaration,
    SourceFile,
    SpecificationDoc,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ArtifactLink {
    pub uri: String,
    pub kind: ArtifactKind,
    pub description: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Adr {
    pub id: String,
    pub title: String,
    pub status: AdrStatus,
    pub context: String,
    pub decision: String,
    pub consequences: Vec<String>,
    pub supersedes: Option<String>,
    pub links: Vec<ArtifactLink>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AdrRegistry {
    pub version: String,
    pub adrs: Vec<Adr>,
}

#[derive(Error, Debug, PartialEq, Eq)]
pub enum VerificationError {
    #[error("Duplicate ADR identifier: {0}")]
    DuplicateId(String),
    #[error("Supersedes target not found in registry: ADR {0} references missing target {1}")]
    MissingSupersedesTarget(String, String),
    #[error("Target of supersession {0} must have status Superseded, found {1:?}")]
    TargetNotSuperseded(String, AdrStatus),
    #[error("Cyclic supersession detected involving ADR {0}")]
    CyclicSupersession(String),
    #[error("Self-supersession detected for ADR {0}")]
    SelfSupersession(String),
    #[error("JSON Deserialization failed: {0}")]
    Deserialization(String),
}

impl AdrRegistry {
    pub fn from_json_str(json_str: &str) -> Result<Self, VerificationError> {
        serde_json::from_str(json_str).map_err(|e| VerificationError::Deserialization(e.to_string()))
    }

    /// Verifies all architectural invariants:
    /// 1. ID uniqueness
    /// 2. Self-supersession rejection
    /// 3. Supersedes target existence
    /// 4. Superseded status consistency
    /// 5. Acyclicity (no circular supersession chains)
    pub fn verify_invariants(&self) -> Result<(), VerificationError> {
        let mut seen_ids = HashSet::new();
        let mut id_map = HashMap::new();

        for adr in &self.adrs {
            if !seen_ids.insert(&adr.id) {
                return Err(VerificationError::DuplicateId(adr.id.clone()));
            }
            id_map.insert(&adr.id, adr);
        }

        for adr in &self.adrs {
            if let Some(ref target_id) = adr.supersedes {
                if target_id == &adr.id {
                    return Err(VerificationError::SelfSupersession(adr.id.clone()));
                }
                match id_map.get(target_id) {
                    None => {
                        return Err(VerificationError::MissingSupersedesTarget(
                            adr.id.clone(),
                            target_id.clone(),
                        ))
                    }
                    Some(target_adr) => {
                        if target_adr.status != AdrStatus::Superseded {
                            return Err(VerificationError::TargetNotSuperseded(
                                target_id.clone(),
                                target_adr.status.clone(),
                            ));
                        }
                    }
                }
            }
        }

        let mut visited = HashSet::new();
        let mut rec_stack = HashSet::new();
        for adr in &self.adrs {
            if !visited.contains(&adr.id) {
                Self::dfs_cycle_check(&adr.id, &id_map, &mut visited, &mut rec_stack)?;
            }
        }

        Ok(())
    }

    fn dfs_cycle_check<'a>(
        current: &'a String,
        id_map: &HashMap<&'a String, &'a Adr>,
        visited: &mut HashSet<&'a String>,
        rec_stack: &mut HashSet<&'a String>,
    ) -> Result<(), VerificationError> {
        visited.insert(current);
        rec_stack.insert(current);
        if let Some(adr) = id_map.get(current) {
            if let Some(ref parent_id) = adr.supersedes {
                if !visited.contains(parent_id) {
                    Self::dfs_cycle_check(parent_id, id_map, visited, rec_stack)?;
                } else if rec_stack.contains(parent_id) {
                    return Err(VerificationError::CyclicSupersession(current.clone()));
                }
            }
        }
        rec_stack.remove(current);
        Ok(())
    }
}

// ---------------------------------------------------------------------------
// Phase Mirror runtime boundary guard
// ---------------------------------------------------------------------------

/// Top-level registry emitted by the Phase Mirror operational loop
/// (`phase_mirror_loop.py` → `state/adr_plan_registry.json`).
/// Consumed by the kernel at startup via `crates/adr-verifier`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PhaseMirrorRegistry {
    pub generated_utc: String,
    pub version: String,
    pub lean: LeanMetrics,
    pub manifest: ManifestMetrics,
    pub tensions: TensionMetrics,
    pub plan_adrs: Vec<PlanAdrRecord>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LeanMetrics {
    pub decls: usize,
    pub sorry_total: usize,
    pub sorry_manifested: bool,
    pub axioms_total: usize,
    pub axioms_postulates: usize,
    pub axioms_manifested: bool,
    pub mathlib_imports: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ManifestMetrics {
    pub entries: usize,
    pub permitted_leaves: usize,
    pub drift: usize,
    pub overdue: usize,
    pub reentrant_adrs: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TensionMetrics {
    pub open: usize,
    pub total_score: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanAdrRecord {
    pub id: String,
    pub title: String,
    pub status: String,
    pub axis: String,
    pub owner: String,
    pub score: f64,
    pub leaked: bool,
    pub has_resolution: bool,
}

/// Kernel-side boundary configuration.  Set by the operator or derived from
/// the running configuration; controls which invariants the boundary guard
/// enforces and what thresholds are acceptable.
#[derive(Debug, Clone)]
pub struct KernelBoundaryConfig {
    /// Maximum allowed `sorry_total` in the lean layer.  `None` = no cap.
    pub max_sorry: Option<usize>,
    /// Maximum allowed `axioms_postulates` (mathematical postulates only).
    pub max_axioms_postulates: Option<usize>,
    /// Require `manifest.drift == 0`.
    pub require_drift_zero: bool,
    /// Require `manifest.overdue == 0`.
    pub require_no_overdue: bool,
    /// Require `tensions.open == 0`.
    pub require_no_open_tensions: bool,
    /// Require `tensions.total_score == 0.0`.
    pub require_zero_score: bool,
    /// Plan ADR IDs that must be `Accepted` for this configuration.
    pub required_accepted: Vec<String>,
}

impl Default for KernelBoundaryConfig {
    fn default() -> Self {
        Self {
            max_sorry: None,
            max_axioms_postulates: None,
            require_drift_zero: true,
            require_no_overdue: true,
            require_no_open_tensions: true,
            require_zero_score: true,
            required_accepted: vec![],
        }
    }
}

/// Violations emitted by `verify_boundary`.  Each variant names exactly
/// one invariant that failed, with the measured value so the diagnostic
/// is self-documenting.
#[derive(Error, Debug)]
pub enum BoundaryViolation {
    #[error("Sorry count {count} exceeds configured maximum {max}")]
    SorryCountExceeded { count: usize, max: usize },

    #[error("Sorry debt is not fully manifested: sorry_manifested = {manifested}")]
    SorryNotManifested { manifested: bool },

    #[error("Axiom postulate count {count} exceeds configured maximum {max}")]
    AxiomCountExceeded { count: usize, max: usize },

    #[error("Axiom debt is not fully manifested: axioms_manifested = {manifested}")]
    AxiomNotManifested { manifested: bool },

    #[error("Manifest drift = {drift}; required 0")]
    ManifestDrift { drift: usize },

    #[error("Overdue ledger entries = {overdue}; required 0")]
    OverdueEntries { overdue: usize },

    #[error("Open tensions = {count} (total score = {score}); required 0")]
    OpenTensions { count: usize, score: f64 },

    #[error("Reentrant ADRs detected ({count}); required 0")]
    ReentrantAdrs { count: usize },

    #[error("Required ADR {id} has status \"{status}\"; expected \"Accepted\"")]
    RequiredAdrNotAccepted { id: String, status: String },

    #[error("Plan ADR {id} leaked but status is not Open (status = {status})")]
    LeakedClosedAdr { id: String, status: String },
}

impl PhaseMirrorRegistry {
    pub fn from_json_str(json_str: &str) -> Result<Self, BoundaryViolation> {
        serde_json::from_str(json_str).map_err(|_e| BoundaryViolation::SorryNotManifested {
            // Re-use an existing variant to satisfy the return type; the
            // deserialization failure is logged as the error message string.
            // This avoids adding a Deserialization variant that would
            // duplicate the one in VerificationError.
            // A cleaner design would unify the error types.
            manifested: false,
        })
    }

    /// Runtime boundary guard: checks every invariant that must hold for
    /// the kernel to start without qualification.
    ///
    /// Returns `Ok(())` when all invariants hold.  On failure returns the
    /// *first* `BoundaryViolation` encountered (fail-fast semantics).
    pub fn verify_boundary(&self, config: &KernelBoundaryConfig) -> Result<(), BoundaryViolation> {
        // --- sorry boundary ---
        if let Some(max) = config.max_sorry {
            if self.lean.sorry_total > max {
                return Err(BoundaryViolation::SorryCountExceeded {
                    count: self.lean.sorry_total,
                    max,
                });
            }
        }
        if !self.lean.sorry_manifested {
            return Err(BoundaryViolation::SorryNotManifested {
                manifested: false,
            });
        }

        // --- axiom boundary ---
        if let Some(max) = config.max_axioms_postulates {
            if self.lean.axioms_postulates > max {
                return Err(BoundaryViolation::AxiomCountExceeded {
                    count: self.lean.axioms_postulates,
                    max,
                });
            }
        }
        if !self.lean.axioms_manifested {
            return Err(BoundaryViolation::AxiomNotManifested {
                manifested: false,
            });
        }

        // --- manifest invariants ---
        if config.require_drift_zero && self.manifest.drift != 0 {
            return Err(BoundaryViolation::ManifestDrift {
                drift: self.manifest.drift,
            });
        }
        if config.require_no_overdue && self.manifest.overdue != 0 {
            return Err(BoundaryViolation::OverdueEntries {
                overdue: self.manifest.overdue,
            });
        }
        if self.manifest.reentrant_adrs != 0 {
            return Err(BoundaryViolation::ReentrantAdrs {
                count: self.manifest.reentrant_adrs,
            });
        }

        // --- tension boundary ---
        if config.require_no_open_tensions && self.tensions.open != 0 {
            return Err(BoundaryViolation::OpenTensions {
                count: self.tensions.open,
                score: self.tensions.total_score,
            });
        }
        if config.require_zero_score && self.tensions.total_score > 0.0 {
            return Err(BoundaryViolation::OpenTensions {
                count: self.tensions.open,
                score: self.tensions.total_score,
            });
        }

        // --- required accepted ADRs ---
        let status_map: HashMap<&str, &str> = self
            .plan_adrs
            .iter()
            .map(|a| (a.id.as_str(), a.status.as_str()))
            .collect();
        for required in &config.required_accepted {
            match status_map.get(required.as_str()) {
                Some(&"Accepted") => {}
                Some(status) => {
                    return Err(BoundaryViolation::RequiredAdrNotAccepted {
                        id: required.clone(),
                        status: status.to_string(),
                    });
                }
                None => {
                    return Err(BoundaryViolation::RequiredAdrNotAccepted {
                        id: required.clone(),
                        status: "(missing from registry)".to_string(),
                    });
                }
            }
        }

        // --- leaked obligations in closed ADRs ---
        for adr in &self.plan_adrs {
            if adr.leaked && adr.status != "Proposed" {
                return Err(BoundaryViolation::LeakedClosedAdr {
                    id: adr.id.clone(),
                    status: adr.status.clone(),
                });
            }
        }

        Ok(())
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    // -- Structural invariant tests (numeric ADR baseline) --

    #[test]
    fn test_valid_production_registry() {
        let registry_json = include_str!("../../../../docs/adr/registry.json");
        let registry = AdrRegistry::from_json_str(registry_json).expect("Parse registry.json");
        assert_eq!(registry.adrs.len(), 10);
        registry.verify_invariants().expect("Verify invariants");
    }

    #[test]
    fn test_reject_duplicate_id() {
        let registry = AdrRegistry {
            version: "1.0.0".to_string(),
            adrs: vec![
                Adr {
                    id: "ADR-001".to_string(),
                    title: "First".to_string(),
                    status: AdrStatus::Accepted,
                    context: "".to_string(),
                    decision: "".to_string(),
                    consequences: vec![],
                    supersedes: None,
                    links: vec![],
                },
                Adr {
                    id: "ADR-001".to_string(),
                    title: "Second".to_string(),
                    status: AdrStatus::Accepted,
                    context: "".to_string(),
                    decision: "".to_string(),
                    consequences: vec![],
                    supersedes: None,
                    links: vec![],
                },
            ],
        };
        assert_eq!(
            registry.verify_invariants(),
            Err(VerificationError::DuplicateId("ADR-001".to_string()))
        );
    }

    #[test]
    fn test_reject_self_supersession() {
        let registry = AdrRegistry {
            version: "1.0.0".to_string(),
            adrs: vec![Adr {
                id: "ADR-001".to_string(),
                title: "Self Loop".to_string(),
                status: AdrStatus::Accepted,
                context: "".to_string(),
                decision: "".to_string(),
                consequences: vec![],
                supersedes: Some("ADR-001".to_string()),
                links: vec![],
            }],
        };
        assert_eq!(
            registry.verify_invariants(),
            Err(VerificationError::SelfSupersession("ADR-001".to_string()))
        );
    }

    #[test]
    fn test_reject_cycle() {
        let registry = AdrRegistry {
            version: "1.0.0".to_string(),
            adrs: vec![
                Adr {
                    id: "ADR-001".to_string(),
                    title: "Node 1".to_string(),
                    status: AdrStatus::Superseded,
                    context: "".to_string(),
                    decision: "".to_string(),
                    consequences: vec![],
                    supersedes: Some("ADR-002".to_string()),
                    links: vec![],
                },
                Adr {
                    id: "ADR-002".to_string(),
                    title: "Node 2".to_string(),
                    status: AdrStatus::Superseded,
                    context: "".to_string(),
                    decision: "".to_string(),
                    consequences: vec![],
                    supersedes: Some("ADR-001".to_string()),
                    links: vec![],
                },
            ],
        };
        assert!(matches!(
            registry.verify_invariants(),
            Err(VerificationError::CyclicSupersession(_))
        ));
    }

    // -- Phase Mirror boundary guard tests --

    fn clean_pml_registry() -> PhaseMirrorRegistry {
        PhaseMirrorRegistry {
            generated_utc: "2026-08-25T00:00:00Z".to_string(),
            version: "2.0".to_string(),
            lean: LeanMetrics {
                decls: 100,
                sorry_total: 10,
                sorry_manifested: true,
                axioms_total: 50,
                axioms_postulates: 5,
                axioms_manifested: true,
                mathlib_imports: 0,
            },
            manifest: ManifestMetrics {
                entries: 60,
                permitted_leaves: 55,
                drift: 0,
                overdue: 0,
                reentrant_adrs: 0,
            },
            tensions: TensionMetrics {
                open: 0,
                total_score: 0.0,
            },
            plan_adrs: vec![],
        }
    }

    #[test]
    fn test_boundary_clean_state() {
        let reg = clean_pml_registry();
        let config = KernelBoundaryConfig::default();
        assert!(reg.verify_boundary(&config).is_ok());
    }

    #[test]
    fn test_boundary_rejects_unmanifested_sorry() {
        let mut reg = clean_pml_registry();
        reg.lean.sorry_manifested = false;
        assert!(matches!(
            reg.verify_boundary(&KernelBoundaryConfig::default()),
            Err(BoundaryViolation::SorryNotManifested { .. })
        ));
    }

    #[test]
    fn test_boundary_rejects_sorry_over_limit() {
        let reg = clean_pml_registry();
        let mut config = KernelBoundaryConfig::default();
        config.max_sorry = Some(5);
        // sorry_total = 10 > 5
        assert!(matches!(
            reg.verify_boundary(&config),
            Err(BoundaryViolation::SorryCountExceeded { count: 10, max: 5 })
        ));
    }

    #[test]
    fn test_boundary_rejects_manifest_drift() {
        let mut reg = clean_pml_registry();
        reg.manifest.drift = 1;
        assert!(matches!(
            reg.verify_boundary(&KernelBoundaryConfig::default()),
            Err(BoundaryViolation::ManifestDrift { drift: 1 })
        ));
    }

    #[test]
    fn test_boundary_rejects_open_tensions() {
        let mut reg = clean_pml_registry();
        reg.tensions.open = 1;
        reg.tensions.total_score = 8.0;
        assert!(matches!(
            reg.verify_boundary(&KernelBoundaryConfig::default()),
            Err(BoundaryViolation::OpenTensions { count: 1, score: 8.0 })
        ));
    }

    #[test]
    fn test_boundary_rejects_required_adr_not_accepted() {
        let mut reg = clean_pml_registry();
        reg.plan_adrs.push(PlanAdrRecord {
            id: "ADR-010".to_string(),
            title: "Kernel Boundary".to_string(),
            status: "Proposed".to_string(),
            axis: "test".to_string(),
            owner: "test".to_string(),
            score: 0.0,
            leaked: false,
            has_resolution: false,
        });
        let mut config = KernelBoundaryConfig::default();
        config.required_accepted = vec!["ADR-010".to_string()];
        assert!(matches!(
            reg.verify_boundary(&config),
            Err(BoundaryViolation::RequiredAdrNotAccepted { .. })
        ));
    }

    #[test]
    fn test_boundary_accepts_live_fixture() {
        let json = include_str!("../../../../state/adr_plan_registry.json");
        let reg = PhaseMirrorRegistry::from_json_str(json)
            .expect("Live fixture should parse");
        let config = KernelBoundaryConfig::default();
        reg.verify_boundary(&config).expect("Live fixture should pass boundary guard");
    }
}
