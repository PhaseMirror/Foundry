use crate::{proof::ProofArtifact, stratify::ValidationResult};
use anyhow::Result;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ReportFormat {
    Json,
    Text,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Report {
    pub admissible: bool,
    pub levels: std::collections::BTreeMap<String, i32>,
    pub issues: Vec<crate::stratify::ValidationIssue>,
    pub proof: ProofArtifact,
}

impl Report {
    pub fn from_validation(validation: ValidationResult) -> Self {
        let proof = ProofArtifact::from_validation(&validation);
        Self {
            admissible: validation.admissible,
            levels: validation.levels,
            issues: validation.issues,
            proof,
        }
    }

    pub fn render(&self, format: ReportFormat) -> Result<String> {
        Ok(match format {
            ReportFormat::Json => serde_json::to_string_pretty(self)?,
            ReportFormat::Text => {
                let mut out = String::new();
                out.push_str(&format!("admissible: {}\n", self.admissible));
                out.push_str("levels:\n");
                for (k, v) in &self.levels {
                    out.push_str(&format!("  - {} => {}\n", k, v));
                }
                if self.issues.is_empty() {
                    out.push_str("issues: none\n");
                } else {
                    out.push_str("issues:\n");
                    for issue in &self.issues {
                        out.push_str(&format!("  - [{}] {}\n", issue.code, issue.message));
                    }
                }
                out.push_str("proof:\n");
                out.push_str(&self.proof.body);
                out
            }
        })
    }
}
