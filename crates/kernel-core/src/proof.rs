use crate::stratify::ValidationResult;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProofArtifact {
    pub title: String,
    pub body: String,
}

impl ProofArtifact {
    pub fn from_validation(result: &ValidationResult) -> Self {
        let mut body = String::new();
        if result.admissible {
            body.push_str("A consistent NF-style level assignment exists.\n");
            for (symbol, level) in &result.levels {
                body.push_str(&format!("- level({symbol}) = {level}\n"));
            }
            body.push_str("Every membership edge ascends exactly one level, equality preserves level, and calls ascend strictly.\n");
            body.push_str("Therefore no admissible evaluation cycle exists under the current rule set.\n");
        } else {
            body.push_str("No proof of non-cyclicity can be constructed.\n");
            for issue in &result.issues {
                body.push_str(&format!("- [{}] {}\n", issue.code, issue.message));
            }
        }
        Self {
            title: "NF stratification proof artifact".into(),
            body,
        }
    }
}
