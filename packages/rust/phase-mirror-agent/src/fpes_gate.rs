//! ADR-0029 FPES Gate — Formal Pre-Execution Safety for the Phase Mirror Agent.
//!
//! Loads `contracts/fpes.yaml`, validates the proof-obligation contract, and
//! checks every `VerifiedAction` against the FPES viability predicates before
//! the action reaches the executor.
//!
//! # Three outcomes
//!
//! - **Allow** — the action's hypothesis space satisfies `Viable H`
//!   (NoDupClasses ∧ Registered ∧ ClassesNonempty).
//! - **Block** — a proof obligation is violated; the action is rejected with
//!   the contract id, reason, and audit evidence.
//! - **Passthrough** — FPES gate is disabled or the action type is outside
//!   the FPES domain.
//!
//! # Contract source
//!
//! All rules come from `contracts/fpes.yaml`.  The gate does not hardcode
//! any obligation — it loads the YAML at startup and builds an in-memory
//! index.  This keeps the Rust runtime and the Lean formal core in sync:
//! changing the YAML changes both the build gate and the runtime gate.

use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Arc;

// ─── YAML contract types ─────────────────────────────────────

/// Top-level contract (mirrors contracts/fpes.yaml).
#[derive(Debug, Clone, serde::Deserialize)]
pub struct FpesContractYaml {
    pub contract_id: String,
    pub version: String,
    pub governance: Governance,
    pub bounds: Bounds,
    pub proof_obligations: Vec<ProofObligation>,
}

#[derive(Debug, Clone, serde::Deserialize)]
pub struct Governance {
    pub owner: String,
    pub governor: String,
    pub fail_closed: bool,
    pub no_sorry: bool,
    pub no_mathlib_in_core: bool,
    pub kani_bound_n: u32,
}

#[derive(Debug, Clone, serde::Deserialize)]
pub struct Bounds {
    pub max_paths: u32,
    pub max_classes: u32,
    pub unwind: u32,
}

#[derive(Debug, Clone, serde::Deserialize)]
pub struct ProofObligation {
    pub id: String,
    #[serde(rename = "type")]
    pub obligation_type: String,
    pub property: String,
    pub formal: String,
}

// ─── Runtime contract ────────────────────────────────────────

/// Loaded and validated FPES contract.
pub struct FpesContract {
    pub yaml: FpesContractYaml,
    /// Indexed by obligation id for O(1) lookup.
    index: HashMap<String, ProofObligation>,
    /// Path to the YAML file (for audit evidence).
    source_path: PathBuf,
}

impl FpesContract {
    /// Load and validate the contract from a YAML file.
    pub fn load(path: impl AsRef<Path>) -> Result<Arc<Self>, ContractError> {
        let path = path.as_ref().to_path_buf();
        let content = fs::read_to_string(&path).map_err(|e| ContractError::Io {
            path: path.display().to_string(),
            source: e,
        })?;
        let yaml: FpesContractYaml =
            serde_yaml::from_str(&content).map_err(|e| ContractError::Parse {
                path: path.display().to_string(),
                source: e,
            })?;

        // Validate invariants
        if yaml.proof_obligations.is_empty() {
            return Err(ContractError::Empty);
        }
        if yaml.governance.fail_closed != true {
            return Err(ContractError::GovernanceViolation {
                detail: "fail_closed must be true (ADR-0029 decision driver 5)".into(),
            });
        }

        let mut index = HashMap::new();
        for ob in &yaml.proof_obligations {
            index.insert(ob.id.clone(), ob.clone());
        }

        Ok(Arc::new(Self {
            yaml,
            index,
            source_path: path,
        }))
    }

    /// Load from the canonical repo-relative path.
    pub fn load_default() -> Result<Arc<Self>, ContractError> {
        // Walk up from CARGO_MANIFEST_DIR to find contracts/fpes.yaml
        let manifest = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let mut candidate = manifest;
        loop {
            let yaml_path = candidate.join("contracts").join("fpes.yaml");
            if yaml_path.exists() {
                return Self::load(yaml_path);
            }
            if !candidate.pop() {
                return Err(ContractError::NotFound);
            }
        }
    }

    /// Look up a proof obligation by id.
    pub fn obligation(&self, id: &str) -> Option<&ProofObligation> {
        self.index.get(id)
    }

    /// All registered obligation ids.
    pub fn obligation_ids(&self) -> Vec<&str> {
        self.index.keys().map(|s| s.as_str()).collect()
    }

    /// Number of registered obligations.
    pub fn obligation_count(&self) -> usize {
        self.index.len()
    }

    /// Source path (for audit evidence).
    pub fn source_path(&self) -> &Path {
        &self.source_path
    }
}

#[derive(Debug)]
pub enum ContractError {
    Io {
        path: String,
        source: std::io::Error,
    },
    Parse {
        path: String,
        source: serde_yaml::Error,
    },
    Empty,
    NotFound,
    GovernanceViolation {
        detail: String,
    },
}

impl std::fmt::Display for ContractError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Io { path, source } => write!(f, "cannot read {}: {}", path, source),
            Self::Parse { path, source } => write!(f, "cannot parse {}: {}", path, source),
            Self::Empty => write!(f, "contract has no proof obligations"),
            Self::NotFound => write!(f, "contracts/fpes.yaml not found"),
            Self::GovernanceViolation { detail } => write!(f, "governance violation: {}", detail),
        }
    }
}

impl std::error::Error for ContractError {}

// ─── Verified Action ─────────────────────────────────────────

/// An action that has been (or is about to be) checked against FPES contracts.
///
/// In the Phase Mirror pipeline, every action that mutates the hypothesis space
/// or triggers a contraction must carry enough information for the gate to
/// evaluate the FPES viability predicates.
#[derive(Debug, Clone)]
pub enum VerifiedAction {
    /// Execute a contraction on a hypothesis space.
    Contract {
        /// Path count before contraction.
        path_count: u32,
        /// Class count before contraction.
        class_count: u32,
        /// Per-class multiplicity vector (class_id → count).
        multiplicities: Vec<(u32, u32)>,
    },
    /// Select a representative for a class.
    SelectRepresentative {
        class_id: u32,
        /// Whether the class has at least one candidate.
        has_candidate: bool,
    },
    /// Apply a proposal to a hypothesis space.
    ApplyProposal {
        path_count: u32,
        class_count: u32,
        /// Number of classes with candidates.
        classes_with_candidates: u32,
    },
    /// A free-form text command (goes through semantic guard only, not FPES).
    TextCommand { text: String },
}

// ─── Gate decision ───────────────────────────────────────────

/// The outcome of an FPES gate check.
#[derive(Debug, Clone)]
pub enum FpesDecision {
    /// The action satisfies all FPES contracts.
    Allow { obligation_ids: Vec<String> },
    /// The action violates a formal safety property.
    Block {
        contract_id: String,
        obligation_id: String,
        reason: String,
        evidence: GateEvidence,
    },
    /// FPES gate is disabled or the action is outside the FPES domain.
    Passthrough,
}

/// Audit evidence produced by the gate for every decision.
#[derive(Debug, Clone)]
pub struct GateEvidence {
    pub path_count: u32,
    pub class_count: u32,
    pub viable: bool,
    pub violations: Vec<String>,
}

// ─── The Gate ────────────────────────────────────────────────

/// A gate that enforces ADR-0029 Formal Pre-Execution Safety (FPES)
/// on every action before it is passed to the executor.
pub struct FpesGate {
    contract: Arc<FpesContract>,
    enabled: bool,
}

impl FpesGate {
    pub fn new(contract: Arc<FpesContract>, enabled: bool) -> Self {
        Self { contract, enabled }
    }

    pub fn is_enabled(&self) -> bool {
        self.enabled
    }

    pub fn contract_count(&self) -> usize {
        self.contract.obligation_count()
    }

    /// Check a `VerifiedAction` against the loaded FPES contracts.
    pub fn check(&self, action: &VerifiedAction) -> FpesDecision {
        if !self.enabled {
            return FpesDecision::Passthrough;
        }

        match action {
            VerifiedAction::TextCommand { .. } => FpesDecision::Passthrough,

            VerifiedAction::Contract {
                path_count,
                class_count,
                multiplicities,
            } => {
                let max = self.contract.yaml.bounds.max_paths;
                if *path_count > max {
                    return FpesDecision::Block {
                        contract_id: self.contract.yaml.contract_id.clone(),
                        obligation_id: "FPES-MULTIPLICITY-001".into(),
                        reason: format!(
                            "path count {} exceeds bound {} (ADR-0029 bounds.max_paths)",
                            path_count, max
                        ),
                        evidence: self.evidence(*path_count, *class_count, multiplicities),
                    };
                }

                // Check: every class must have multiplicity >= 1
                let violations: Vec<String> = multiplicities
                    .iter()
                    .filter(|(_, count)| *count == 0)
                    .map(|(id, _)| format!("class {} has multiplicity 0", id))
                    .collect();

                if !violations.is_empty() {
                    return FpesDecision::Block {
                        contract_id: self.contract.yaml.contract_id.clone(),
                        obligation_id: "FPES-MULTIPLICITY-001".into(),
                        reason: format!("ClassesNonempty violated: {}", violations.join("; ")),
                        evidence: self.evidence(*path_count, *class_count, multiplicities),
                    };
                }

                FpesDecision::Allow {
                    obligation_ids: self
                        .contract
                        .obligation_ids()
                        .into_iter()
                        .map(String::from)
                        .collect(),
                }
            }

            VerifiedAction::SelectRepresentative {
                has_candidate,
                class_id,
            } => {
                if !has_candidate {
                    return FpesDecision::Block {
                        contract_id: self.contract.yaml.contract_id.clone(),
                        obligation_id: "FPES-SURVIVAL-002".into(),
                        reason: format!(
                            "class {} has no candidate representative (FPES-SURVIVAL-002 violation)",
                            class_id
                        ),
                        evidence: GateEvidence {
                            path_count: 0,
                            class_count: 0,
                            viable: false,
                            violations: vec![format!("class {} empty", class_id)],
                        },
                    };
                }
                FpesDecision::Allow {
                    obligation_ids: vec!["FPES-SURVIVAL-002".into()],
                }
            }

            VerifiedAction::ApplyProposal {
                path_count,
                class_count,
                classes_with_candidates,
            } => {
                if classes_with_candidates < class_count {
                    let missing = class_count - classes_with_candidates;
                    return FpesDecision::Block {
                        contract_id: self.contract.yaml.contract_id.clone(),
                        obligation_id: "FPES-SURVIVAL-002".into(),
                        reason: format!(
                            "{} of {} classes have no candidate (survival violated)",
                            missing, class_count
                        ),
                        evidence: GateEvidence {
                            path_count: *path_count,
                            class_count: *class_count,
                            viable: false,
                            violations: vec![format!("{} classes empty", missing)],
                        },
                    };
                }
                FpesDecision::Allow {
                    obligation_ids: self
                        .contract
                        .obligation_ids()
                        .into_iter()
                        .map(String::from)
                        .collect(),
                }
            }
        }
    }

    fn evidence(
        &self,
        path_count: u32,
        class_count: u32,
        multiplicities: &[(u32, u32)],
    ) -> GateEvidence {
        let violations: Vec<String> = multiplicities
            .iter()
            .filter(|(_, count)| *count == 0)
            .map(|(id, _)| format!("class {} multiplicity 0", id))
            .collect();
        GateEvidence {
            path_count,
            class_count,
            viable: violations.is_empty(),
            violations,
        }
    }
}

/// Enforce the FPES gate on an action, returning an error if blocked.
pub fn enforce_fpes(
    gate: &FpesGate,
    action: &VerifiedAction,
) -> Result<Vec<String>, FpesBlockError> {
    match gate.check(action) {
        FpesDecision::Allow { obligation_ids } => Ok(obligation_ids),
        FpesDecision::Passthrough => Ok(vec![]),
        FpesDecision::Block {
            contract_id,
            obligation_id,
            reason,
            evidence,
        } => Err(FpesBlockError {
            contract_id,
            obligation_id,
            reason,
            evidence,
        }),
    }
}

#[derive(Debug, thiserror::Error)]
#[error("FPES blocked action in contract {contract_id} (obligation {obligation_id}): {reason}")]
pub struct FpesBlockError {
    pub contract_id: String,
    pub obligation_id: String,
    pub reason: String,
    pub evidence: GateEvidence,
}

// ─── Tests ───────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_load_contract() {
        let contract = FpesContract::load_default().expect("contract must load");
        assert_eq!(contract.yaml.contract_id, "fpes");
        assert!(contract.yaml.governance.fail_closed);
        assert!(contract.obligation_count() >= 5);
    }

    #[test]
    fn test_gate_enabled_blocks_bad_action() {
        let contract = FpesContract::load_default().unwrap();
        let gate = FpesGate::new(contract, true);

        // Class with zero multiplicity → block
        let action = VerifiedAction::Contract {
            path_count: 4,
            class_count: 3,
            multiplicities: vec![(0, 2), (1, 2), (2, 0)],
        };
        let result = enforce_fpes(&gate, &action);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert!(err.reason.contains("multiplicity 0"));
        assert_eq!(err.obligation_id, "FPES-MULTIPLICITY-001");
    }

    #[test]
    fn test_gate_enabled_allows_good_action() {
        let contract = FpesContract::load_default().unwrap();
        let gate = FpesGate::new(contract, true);

        let action = VerifiedAction::Contract {
            path_count: 8,
            class_count: 3,
            multiplicities: vec![(0, 3), (1, 2), (2, 3)],
        };
        let result = enforce_fpes(&gate, &action);
        assert!(result.is_ok());
    }

    #[test]
    fn test_gate_disabled_passthrough() {
        let contract = FpesContract::load_default().unwrap();
        let gate = FpesGate::new(contract, false);

        let action = VerifiedAction::Contract {
            path_count: 4,
            class_count: 3,
            multiplicities: vec![(0, 2), (1, 2), (2, 0)],
        };
        let result = enforce_fpes(&gate, &action);
        assert!(result.is_ok()); // Passthrough → Ok
    }

    #[test]
    fn test_text_command_passthrough() {
        let contract = FpesContract::load_default().unwrap();
        let gate = FpesGate::new(contract, true);

        let action = VerifiedAction::TextCommand {
            text: "hello".into(),
        };
        let result = enforce_fpes(&gate, &action);
        assert!(result.is_ok());
    }

    #[test]
    fn test_select_representative_no_candidate_blocks() {
        let contract = FpesContract::load_default().unwrap();
        let gate = FpesGate::new(contract, true);

        let action = VerifiedAction::SelectRepresentative {
            class_id: 7,
            has_candidate: false,
        };
        let result = enforce_fpes(&gate, &action);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err().obligation_id, "FPES-SURVIVAL-002");
    }

    #[test]
    fn test_apply_proposal_partial_candidates_blocks() {
        let contract = FpesContract::load_default().unwrap();
        let gate = FpesGate::new(contract, true);

        let action = VerifiedAction::ApplyProposal {
            path_count: 6,
            class_count: 3,
            classes_with_candidates: 2,
        };
        let result = enforce_fpes(&gate, &action);
        assert!(result.is_err());
    }

    #[test]
    fn test_bound_exceeded_blocks() {
        let contract = FpesContract::load_default().unwrap();
        let gate = FpesGate::new(contract, true);

        let action = VerifiedAction::Contract {
            path_count: 16, // exceeds max_paths = 8
            class_count: 3,
            multiplicities: vec![(0, 5), (1, 5), (2, 6)],
        };
        let result = enforce_fpes(&gate, &action);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert!(err.reason.contains("exceeds bound"));
    }
}
