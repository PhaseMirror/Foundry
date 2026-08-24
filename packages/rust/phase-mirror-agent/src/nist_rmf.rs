//! NIST AI RMF 1.0 Compliance Mapping — Phase Mirror Architecture
//!
//! Loads `contracts/nist_rmf_mapping.yaml`, maps every FPES gate decision
//! to the specific NIST RMF function and category it enforces, and produces
//! machine-readable audit entries that regulators can query.
//!
//! # Architecture
//!
//! ```text
//! NistRmfMapping (YAML)
//!   ├── GOVERN × 5 categories  → build gates, type system, proofs
//!   ├── MAP × 5 categories     → formal model, Kani, regression vectors
//!   ├── MEASURE × 5 categories → runtime checks, operator norm bounds
//!   └── MANAGE × 5 categories  → fail-closed, CRMF audit ledger
//!
//! NistRmfAuditEntry (per gate decision)
//!   ├── trace_id, timestamp
//!   ├── nist_function, nist_category_id
//!   ├── enforcement_type, enforcement_artifact
//!   ├── proof_artifact (Lean theorem path)
//!   ├── gate_decision (Allow/Block/Passthrough)
//!   └── obligation_id, reason, evidence
//! ```
//!
//! Every FPES gate decision produces a `NistRmfAuditEntry`.  The entry
//! records which NIST category was enforced, what proof artifact backs it,
//! and what the gate decided.  This is the machine-readable compliance
//! receipt that replaces human-authored policy narratives.

use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Arc;

use serde::{Deserialize, Serialize};

// ─── NIST RMF function/category enums ────────────────────────

/// The four NIST AI RMF 1.0 core functions.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "UPPERCASE")]
pub enum NistFunction {
    Govern,
    Map,
    Measure,
    Manage,
}

impl std::fmt::Display for NistFunction {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Govern => write!(f, "GOVERN"),
            Self::Map => write!(f, "MAP"),
            Self::Measure => write!(f, "MEASURE"),
            Self::Manage => write!(f, "MANAGE"),
        }
    }
}

/// How a NIST category is enforced in the Phase Mirror system.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EnforcementType {
    BuildGate,
    RuntimeGate,
    FormalProof,
    FormalModel,
    TypeSystem,
    CiPipeline,
    AuditEntry,
    KaniHarness,
    RegressionVector,
    FailClosed,
    YamlContract,
    CompileTime,
    AuditApi,
}

impl std::fmt::Display for EnforcementType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::BuildGate => write!(f, "build_gate"),
            Self::RuntimeGate => write!(f, "runtime_gate"),
            Self::FormalProof => write!(f, "formal_proof"),
            Self::FormalModel => write!(f, "formal_model"),
            Self::TypeSystem => write!(f, "type_system"),
            Self::CiPipeline => write!(f, "ci_pipeline"),
            Self::AuditEntry => write!(f, "audit_entry"),
            Self::KaniHarness => write!(f, "kani_harness"),
            Self::RegressionVector => write!(f, "regression_vector"),
            Self::FailClosed => write!(f, "fail_closed"),
            Self::YamlContract => write!(f, "yaml_contract"),
            Self::CompileTime => write!(f, "compile_time"),
            Self::AuditApi => write!(f, "audit_api"),
        }
    }
}

/// The outcome of an FPES gate decision.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "PascalCase")]
pub enum GateDecision {
    Allow,
    Block,
    Passthrough,
}

// ─── YAML mapping types ──────────────────────────────────────

#[derive(Debug, Clone, Deserialize)]
pub struct NistRmfYaml {
    pub framework: Framework,
    pub govern: FunctionBlock,
    pub map: FunctionBlock,
    pub measure: FunctionBlock,
    pub manage: FunctionBlock,
}

#[derive(Debug, Clone, Deserialize)]
pub struct Framework {
    pub name: String,
    pub version: String,
    pub mapping_version: String,
    pub generated_from: String,
    pub system: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct FunctionBlock {
    pub description: String,
    pub categories: Vec<CategoryYaml>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct CategoryYaml {
    pub id: String,
    pub nist_title: String,
    pub enforcement: EnforcementYaml,
    pub proof_artifact: Option<String>,
    pub adr: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct EnforcementYaml {
    #[serde(rename = "type")]
    pub enforcement_type: EnforcementType,
    pub artifact: String,
    pub check: String,
    #[serde(flatten)]
    pub mechanism: EnforcementMechanism,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(untagged)]
pub enum EnforcementMechanism {
    WithCommand {
        command: String,
        exit_code_required: u32,
    },
    WithMechanism {
        mechanism: String,
    },
    Plain,
}

// ─── Loaded mapping ──────────────────────────────────────────

/// A loaded and indexed NIST RMF compliance mapping.
pub struct NistRmfMapping {
    pub yaml: NistRmfYaml,
    /// Indexed by category id (e.g., "GOVERN-3") for O(1) lookup.
    index: HashMap<String, LoadedCategory>,
}

#[derive(Debug, Clone)]
struct LoadedCategory {
    pub id: String,
    pub function: NistFunction,
    pub nist_title: String,
    pub enforcement_type: EnforcementType,
    pub enforcement_artifact: String,
    pub enforcement_check: String,
    pub proof_artifact: Option<String>,
    pub adr: String,
}

impl NistRmfMapping {
    /// Load the mapping from a YAML file.
    pub fn load(path: impl AsRef<Path>) -> Result<Arc<Self>, NistError> {
        let path = path.as_ref().to_path_buf();
        let content = fs::read_to_string(&path).map_err(|e| NistError::Io {
            path: path.display().to_string(),
            source: e,
        })?;
        let yaml: NistRmfYaml = serde_yaml::from_str(&content).map_err(|e| NistError::Parse {
            path: path.display().to_string(),
            source: e,
        })?;

        let mut index = HashMap::new();

        for cat in &yaml.govern.categories {
            index.insert(
                cat.id.clone(),
                LoadedCategory {
                    id: cat.id.clone(),
                    function: NistFunction::Govern,
                    nist_title: cat.nist_title.clone(),
                    enforcement_type: cat.enforcement.enforcement_type,
                    enforcement_artifact: cat.enforcement.artifact.clone(),
                    enforcement_check: cat.enforcement.check.clone(),
                    proof_artifact: cat.proof_artifact.clone(),
                    adr: cat.adr.clone(),
                },
            );
        }
        for cat in &yaml.map.categories {
            index.insert(
                cat.id.clone(),
                LoadedCategory {
                    id: cat.id.clone(),
                    function: NistFunction::Map,
                    nist_title: cat.nist_title.clone(),
                    enforcement_type: cat.enforcement.enforcement_type,
                    enforcement_artifact: cat.enforcement.artifact.clone(),
                    enforcement_check: cat.enforcement.check.clone(),
                    proof_artifact: cat.proof_artifact.clone(),
                    adr: cat.adr.clone(),
                },
            );
        }
        for cat in &yaml.measure.categories {
            index.insert(
                cat.id.clone(),
                LoadedCategory {
                    id: cat.id.clone(),
                    function: NistFunction::Measure,
                    nist_title: cat.nist_title.clone(),
                    enforcement_type: cat.enforcement.enforcement_type,
                    enforcement_artifact: cat.enforcement.artifact.clone(),
                    enforcement_check: cat.enforcement.check.clone(),
                    proof_artifact: cat.proof_artifact.clone(),
                    adr: cat.adr.clone(),
                },
            );
        }
        for cat in &yaml.manage.categories {
            index.insert(
                cat.id.clone(),
                LoadedCategory {
                    id: cat.id.clone(),
                    function: NistFunction::Manage,
                    nist_title: cat.nist_title.clone(),
                    enforcement_type: cat.enforcement.enforcement_type,
                    enforcement_artifact: cat.enforcement.artifact.clone(),
                    enforcement_check: cat.enforcement.check.clone(),
                    proof_artifact: cat.proof_artifact.clone(),
                    adr: cat.adr.clone(),
                },
            );
        }

        Ok(Arc::new(Self { yaml, index }))
    }

    /// Load from the canonical repo-relative path.
    pub fn load_default() -> Result<Arc<Self>, NistError> {
        let manifest = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let mut candidate = manifest;
        loop {
            let yaml_path = candidate.join("contracts").join("nist_rmf_mapping.yaml");
            if yaml_path.exists() {
                return Self::load(yaml_path);
            }
            if !candidate.pop() {
                return Err(NistError::NotFound);
            }
        }
    }

    /// Look up a category by id.
    pub fn category(&self, id: &str) -> Option<&LoadedCategory> {
        self.index.get(id)
    }

    /// All registered category ids.
    pub fn category_ids(&self) -> Vec<&str> {
        self.index.keys().map(|s| s.as_str()).collect()
    }

    /// Total number of categories across all four functions.
    pub fn category_count(&self) -> usize {
        self.index.len()
    }

    /// Categories for a specific NIST function.
    pub fn categories_for(&self, function: NistFunction) -> Vec<&LoadedCategory> {
        self.index
            .values()
            .filter(|c| c.function == function)
            .collect()
    }

    /// All categories that have a formal proof artifact.
    pub fn proven_categories(&self) -> Vec<&LoadedCategory> {
        self.index
            .values()
            .filter(|c| c.proof_artifact.is_some())
            .collect()
    }
}

#[derive(Debug)]
pub enum NistError {
    Io {
        path: String,
        source: std::io::Error,
    },
    Parse {
        path: String,
        source: serde_yaml::Error,
    },
    NotFound,
}

impl std::fmt::Display for NistError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Io { path, source } => write!(f, "cannot read {}: {}", path, source),
            Self::Parse { path, source } => write!(f, "cannot parse {}: {}", path, source),
            Self::NotFound => write!(f, "contracts/nist_rmf_mapping.yaml not found"),
        }
    }
}

impl std::error::Error for NistError {}

// ─── NIST-tagged audit entry ─────────────────────────────────

/// An audit entry tagged with the specific NIST RMF category it enforces.
/// Produced by every FPES gate decision.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NistRmfAuditEntry {
    pub trace_id: String,
    pub timestamp: String,
    pub nist_function: NistFunction,
    pub nist_category_id: String,
    pub enforcement_type: EnforcementType,
    pub enforcement_artifact: String,
    pub proof_artifact: Option<String>,
    pub gate_decision: GateDecision,
    pub obligation_id: Option<String>,
    pub reason: Option<String>,
    pub adr: String,
}

impl NistRmfAuditEntry {
    /// Create an audit entry for an FPES gate decision.
    ///
    /// Maps the FPES obligation id to the corresponding NIST category
    /// and produces a fully-tagged audit entry.
    pub fn from_fpes_decision(
        mapping: &NistRmfMapping,
        fpes_decision: &str, // "Allow", "Block", "Passthrough"
        obligation_id: Option<&str>,
        reason: Option<&str>,
    ) -> Self {
        // Map FPES obligation to NIST category
        let (category_id, function) = match obligation_id {
            Some("FPES-MULTIPLICITY-001") => ("GOVERN-2".to_string(), NistFunction::Govern),
            Some("FPES-SURVIVAL-002") => ("MEASURE-2".to_string(), NistFunction::Measure),
            Some("FPES-CONFLICT-005") => ("GOVERN-4".to_string(), NistFunction::Govern),
            Some("FPES-CERTIFICATE-006") => ("GOVERN-3".to_string(), NistFunction::Govern),
            None => ("GOVERN-1".to_string(), NistFunction::Govern),
            _ => ("MEASURE-3".to_string(), NistFunction::Measure),
        };

        let category = mapping.category(&category_id);

        let gate_decision = match fpes_decision {
            "Allow" => GateDecision::Allow,
            "Block" => GateDecision::Block,
            _ => GateDecision::Passthrough,
        };

        Self {
            trace_id: uuid::Uuid::new_v4().to_string(),
            timestamp: chrono::Utc::now().to_rfc3339(),
            nist_function: function,
            nist_category_id: category_id,
            enforcement_type: category
                .map(|c| c.enforcement_type)
                .unwrap_or(EnforcementType::RuntimeGate),
            enforcement_artifact: category
                .map(|c| c.enforcement_artifact.clone())
                .unwrap_or_default(),
            proof_artifact: category.and_then(|c| c.proof_artifact.clone()),
            gate_decision,
            obligation_id: obligation_id.map(String::from),
            reason: reason.map(String::from),
            adr: category.map(|c| c.adr.clone()).unwrap_or_default(),
        }
    }

    /// Serialize to JSON for the audit ledger.
    pub fn to_json(&self) -> String {
        serde_json::to_string(self).expect("NistRmfAuditEntry must serialize")
    }

    /// Serialize to pretty JSON for human inspection.
    pub fn to_json_pretty(&self) -> String {
        serde_json::to_string_pretty(self).expect("NistRmfAuditEntry must serialize")
    }
}

// ─── Compliance status report ─────────────────────────────────

/// A summary report of NIST RMF compliance status.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NistRmfStatus {
    pub framework: String,
    pub version: String,
    pub total_categories: usize,
    pub categories_with_enforcement: usize,
    pub categories_with_proofs: usize,
    pub functions: Vec<NistFunctionStatus>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NistFunctionStatus {
    pub function: NistFunction,
    pub category_count: usize,
    pub enforced_count: usize,
    pub proven_count: usize,
}

impl NistRmfStatus {
    /// Generate a status report from the loaded mapping.
    pub fn from_mapping(mapping: &NistRmfMapping) -> Self {
        let functions = vec![
            NistFunction::Govern,
            NistFunction::Map,
            NistFunction::Measure,
            NistFunction::Manage,
        ]
        .into_iter()
        .map(|f| {
            let cats = mapping.categories_for(f);
            NistFunctionStatus {
                function: f,
                category_count: cats.len(),
                enforced_count: cats.len(), // all have enforcement
                proven_count: cats.iter().filter(|c| c.proof_artifact.is_some()).count(),
            }
        })
        .collect();

        let total = mapping.category_count();
        let proven = mapping.proven_categories().len();

        Self {
            framework: mapping.yaml.framework.name.clone(),
            version: mapping.yaml.framework.mapping_version.clone(),
            total_categories: total,
            categories_with_enforcement: total,
            categories_with_proofs: proven,
            functions,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_load_nist_mapping() {
        let mapping = NistRmfMapping::load_default().expect("mapping must load");
        assert_eq!(mapping.category_count(), 20); // 5 per function × 4 functions
    }

    #[test]
    fn test_all_functions_present() {
        let mapping = NistRmfMapping::load_default().unwrap();
        assert_eq!(mapping.categories_for(NistFunction::Govern).len(), 5);
        assert_eq!(mapping.categories_for(NistFunction::Map).len(), 5);
        assert_eq!(mapping.categories_for(NistFunction::Measure).len(), 5);
        assert_eq!(mapping.categories_for(NistFunction::Manage).len(), 5);
    }

    #[test]
    fn test_proven_categories_exist() {
        let mapping = NistRmfMapping::load_default().unwrap();
        let proven = mapping.proven_categories();
        assert!(
            proven.len() >= 6,
            "at least 6 categories should have Lean proofs"
        );
    }

    #[test]
    fn test_audit_entry_from_multiplicity_violation() {
        let mapping = NistRmfMapping::load_default().unwrap();
        let entry = NistRmfAuditEntry::from_fpes_decision(
            &mapping,
            "Block",
            Some("FPES-MULTIPLICITY-001"),
            Some("class 2 has multiplicity 0"),
        );
        assert_eq!(entry.gate_decision, GateDecision::Block);
        assert_eq!(entry.nist_function, NistFunction::Govern);
        assert_eq!(entry.nist_category_id, "GOVERN-2");
        assert!(entry.proof_artifact.is_some());
    }

    #[test]
    fn test_audit_entry_from_survival_violation() {
        let mapping = NistRmfMapping::load_default().unwrap();
        let entry = NistRmfAuditEntry::from_fpes_decision(
            &mapping,
            "Block",
            Some("FPES-SURVIVAL-002"),
            Some("class 7 has no candidate"),
        );
        assert_eq!(entry.nist_function, NistFunction::Measure);
        assert_eq!(entry.nist_category_id, "MEASURE-2");
    }

    #[test]
    fn test_audit_entry_allow() {
        let mapping = NistRmfMapping::load_default().unwrap();
        let entry = NistRmfAuditEntry::from_fpes_decision(
            &mapping,
            "Allow",
            Some("FPES-MULTIPLICITY-001"),
            None,
        );
        assert_eq!(entry.gate_decision, GateDecision::Allow);
    }

    #[test]
    fn test_status_report() {
        let mapping = NistRmfMapping::load_default().unwrap();
        let status = NistRmfStatus::from_mapping(&mapping);
        assert_eq!(status.total_categories, 20);
        assert_eq!(status.categories_with_enforcement, 20);
        assert!(status.categories_with_proofs >= 6);
    }
}
