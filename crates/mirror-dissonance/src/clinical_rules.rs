use crate::schemas::{RuleViolation, Severity, ClinicalWorkflowInput};

pub fn check_clinical_dissonance(input: &ClinicalWorkflowInput) -> Vec<RuleViolation> {
    let mut violations = Vec::new();

    // CD-001: Human Oversight for Low Confidence
    if input.confidence_score < 0.95 {
        violations.push(RuleViolation {
            rule_id: "CD-001".to_string(),
            severity: Severity::High,
            message: format!(
                "Low confidence score ({:.2}) requires manual clinical concurrence.",
                input.confidence_score
            ),
            context: None,
        });
    }

    // CD-002: Documentation Anchoring
    if !input.justification_anchored {
        violations.push(RuleViolation {
            rule_id: "CD-002".to_string(),
            severity: Severity::Critical,
            message: "Clinical justification is not anchored in Archivum. Decision blocked.".to_string(),
            context: None,
        });
    }

    // CD-003: Prime Epoch Alignment (Gate 1)
    if !is_prime(input.execution_epoch) {
        violations.push(RuleViolation {
            rule_id: "CD-003".to_string(),
            severity: Severity::High,
            message: format!(
                "Execution epoch ({}) is not a prime number. Violates Gate 1 (Envelope).",
                input.execution_epoch
            ),
            context: None,
        });
    }

    // CD-004: Stability Constraint (Gate 2)
    if input.stability_score < 0.82 {
        violations.push(RuleViolation {
            rule_id: "CD-004".to_string(),
            severity: Severity::Critical,
            message: format!(
                "Stability score ({:.4}) below threshold (0.82). Violates Gate 2 (Contraction).",
                input.stability_score
            ),
            context: None,
        });
    }

    violations
}

fn is_prime(n: u64) -> bool {
    if n < 2 { return false; }
    for i in 2..=((n as f64).sqrt() as u64) {
        if n % i == 0 { return false; }
    }
    true
}
