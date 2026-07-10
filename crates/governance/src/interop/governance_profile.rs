use crate::interop::category_model::StatusLevel;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use chrono::Utc;
use sha2::{Sha256, Digest};

/// S-03: Governance Profile Schema — definition, validation, and serialization.

pub const SCHEMA_VERSION: &str = "dcgf.governance_profile.v1";

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ProfileObligation {
    pub obligation_id: String,
    pub label: String,
    pub status: StatusLevel,
    pub framework: String,
    pub dcgf_constraint_id: Option<String>,
}

impl ProfileObligation {
    pub fn new(obligation_id: &str, label: &str, status: StatusLevel, framework: &str, dcgf_constraint_id: Option<&str>) -> Self {
        Self {
            obligation_id: obligation_id.to_string(),
            label: label.to_string(),
            status,
            framework: framework.to_string(),
            dcgf_constraint_id: dcgf_constraint_id.map(|s| s.to_string()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct GovernanceProfile {
    pub profile_id: String,
    pub framework: String,
    pub framework_version: String,
    pub name: String,
    pub obligations: Vec<ProfileObligation>,
    pub metadata: HashMap<String, String>,
    pub schema_version: String,
    pub created_at: String,
}

impl GovernanceProfile {
    pub fn new(profile_id: &str, framework: &str, framework_version: &str, name: &str, obligations: Vec<ProfileObligation>) -> Self {
        Self {
            profile_id: profile_id.to_string(),
            framework: framework.to_string(),
            framework_version: framework_version.to_string(),
            name: name.to_string(),
            obligations,
            metadata: HashMap::new(),
            schema_version: SCHEMA_VERSION.to_string(),
            created_at: Utc::now().to_rfc3339(),
        }
    }

    pub fn validate(&self) -> (bool, Vec<String>) {
        let mut errors = Vec::new();
        if self.schema_version != SCHEMA_VERSION {
            errors.append(&mut vec![format!("Invalid schema version: {}", self.schema_version)]);
        }
        if self.profile_id.is_empty() {
            errors.push("Missing profile_id".to_string());
        }
        if self.framework.is_empty() {
            errors.push("Missing framework".to_string());
        }
        if self.framework_version.is_empty() {
            errors.push("Missing framework_version".to_string());
        }
        if self.name.is_empty() {
            errors.push("Missing name".to_string());
        }
        if self.obligations.is_empty() {
            errors.push("Profile must have at least one obligation".to_string());
        }
        for (i, ob) in self.obligations.iter().enumerate() {
            if ob.obligation_id.is_empty() {
                errors.push(format!("Obligation {}: missing obligation_id", i));
            }
            if ob.label.is_empty() {
                errors.push(format!("Obligation {}: missing label", i));
            }
        }
        (errors.is_empty(), errors)
    }

    pub fn profile_hash(&self) -> String {
        let json = serde_json::to_string(self).unwrap();
        let mut hasher = Sha256::new();
        hasher.update(json.as_bytes());
        hex::encode(hasher.finalize())
    }
}

pub fn _eu_obligations(risk_level: &str) -> Vec<ProfileObligation> {
    let base = match risk_level {
        "high" => StatusLevel::Violation,
        "limited" => StatusLevel::Warning,
        _ => StatusLevel::Ok,
    };
    vec![
        ProfileObligation::new("art9_2a", "Art. 9(2)(a) — Risk identification", base, "eu_ai_act", Some("C01")),
        ProfileObligation::new("art9_2b", "Art. 9(2)(b) — Foreseeable misuse", base, "eu_ai_act", Some("C02")),
        ProfileObligation::new("art9_2c", "Art. 9(2)(c) — Emerging risks", base, "eu_ai_act", Some("C03")),
        ProfileObligation::new("art10", "Art. 10 — Data governance", base, "eu_ai_act", Some("C04")),
        ProfileObligation::new("art5", "Art. 5 — Prohibited AI practices", StatusLevel::Critical, "eu_ai_act", Some("C05")),
        ProfileObligation::new("art9_6", "Art. 9(6) — Testing", base, "eu_ai_act", Some("C06")),
        ProfileObligation::new("art9_7", "Art. 9(7) — Testing for purpose", base, "eu_ai_act", Some("C07")),
        ProfileObligation::new("art9_5", "Art. 9(5) — Residual risk", base, "eu_ai_act", Some("C08")),
        ProfileObligation::new("art9_2d", "Art. 9(2)(d) — Risk measures", base, "eu_ai_act", Some("C09")),
        ProfileObligation::new("art14", "Art. 14 — Human oversight", base, "eu_ai_act", Some("C10")),
        ProfileObligation::new("art11", "Art. 11 — Technical documentation", base, "eu_ai_act", Some("C11")),
    ]
}

pub fn build_eu_high_risk_profile() -> GovernanceProfile {
    GovernanceProfile::new(
        "eu-ai-act-high-risk",
        "eu_ai_act",
        "2024",
        "EU AI Act — High-Risk System",
        _eu_obligations("high"),
    )
}

pub fn build_eu_limited_risk_profile() -> GovernanceProfile {
    GovernanceProfile::new(
        "eu-ai-act-limited-risk",
        "eu_ai_act",
        "2024",
        "EU AI Act — Limited-Risk System",
        _eu_obligations("limited"),
    )
}

pub fn build_nist_rmf_profile() -> GovernanceProfile {
    GovernanceProfile::new(
        "nist-ai-rmf-v1",
        "nist_rmf",
        "1.0",
        "NIST AI RMF v1.0",
        vec![
            ProfileObligation::new("govern_1_1", "GOVERN 1.1 — Policies", StatusLevel::Warning, "nist_rmf", Some("C01")),
            ProfileObligation::new("map_2_2", "MAP 2.2 — Sci/tech framing", StatusLevel::Warning, "nist_rmf", Some("C02")),
            ProfileObligation::new("map_5_1", "MAP 5.1 — Org risk priorities", StatusLevel::Warning, "nist_rmf", Some("C03")),
            ProfileObligation::new("map_2_3", "MAP 2.3 — AI capabilities", StatusLevel::Warning, "nist_rmf", Some("C04")),
            ProfileObligation::new("map_5_2", "MAP 5.2 — Sci/eng basis", StatusLevel::Violation, "nist_rmf", Some("C05")),
            ProfileObligation::new("govern_6_1", "GOVERN 6.1 — Acquisition", StatusLevel::Warning, "nist_rmf", Some("C06")),
            ProfileObligation::new("measure_2_5", "MEASURE 2.5 — Entity eval", StatusLevel::Warning, "nist_rmf", Some("C07")),
            ProfileObligation::new("measure_2_6", "MEASURE 2.6 — System impact", StatusLevel::Violation, "nist_rmf", Some("C08")),
            ProfileObligation::new("manage_3_2", "MANAGE 3.2 — Treatment", StatusLevel::Warning, "nist_rmf", Some("C09")),
            ProfileObligation::new("govern_4_1", "GOVERN 4.1 — Teams", StatusLevel::Warning, "nist_rmf", Some("C10")),
            ProfileObligation::new("govern_6_2", "GOVERN 6.2 — Deployment", StatusLevel::Warning, "nist_rmf", Some("C11")),
        ],
    )
}

pub fn build_iso_42001_profile() -> GovernanceProfile {
    GovernanceProfile::new(
        "iso-42001-v1",
        "iso_42001",
        "2023",
        "ISO 42001:2023 AI Management System",
        vec![
            ProfileObligation::new("iso_7_2", "7.2 — Purpose and scope", StatusLevel::Warning, "iso_42001", Some("C01")),
            ProfileObligation::new("iso_8_1", "8.1 — Measurement systems", StatusLevel::Warning, "iso_42001", Some("C02")),
            ProfileObligation::new("iso_8_2", "8.2 — Evaluation framework", StatusLevel::Warning, "iso_42001", Some("C03")),
            ProfileObligation::new("iso_8_3", "8.3 — Data management", StatusLevel::Warning, "iso_42001", Some("C04")),
            ProfileObligation::new("iso_8_4", "8.4 — Threat modeling", StatusLevel::Violation, "iso_42001", Some("C05")),
            ProfileObligation::new("iso_7_4", "7.4 — Resource allocation", StatusLevel::Warning, "iso_42001", Some("C06")),
            ProfileObligation::new("iso_8_5", "8.5 — Metric governance", StatusLevel::Warning, "iso_42001", Some("C07")),
            ProfileObligation::new("iso_8_6", "8.6 — Scenario analysis", StatusLevel::Warning, "iso_42001", Some("C08")),
            ProfileObligation::new("iso_7_5", "7.5 — Change control", StatusLevel::Warning, "iso_42001", Some("C09")),
            ProfileObligation::new("iso_7_3", "7.3 — Governance structure", StatusLevel::Warning, "iso_42001", Some("C10")),
            ProfileObligation::new("iso_8_7", "8.7 — Federated systems", StatusLevel::Warning, "iso_42001", Some("C11")),
        ],
    )
}
