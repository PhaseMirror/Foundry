use crate::schemas::{RuleViolation, Severity, OracleInput};

pub async fn check_md001(input: &OracleInput) -> Vec<RuleViolation> {
    let mut violations = Vec::new();

    if input.mode == "merge_group" && !input.strict {
        violations.push(RuleViolation {
            rule_id: "MD-001".to_string(),
            severity: Severity::High,
            message: "Branch protection should be enabled with strict mode for merge queue".to_string(),
            context: None,
        });
    }

    violations
}
