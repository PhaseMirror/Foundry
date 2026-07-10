use crate::schemas::{RuleViolation, Severity, MachineDecision, Outcome, OracleInput};
use std::collections::HashMap;
use chrono::Utc;

pub struct Thresholds {
    pub critical: usize,
    pub high: usize,
    pub medium: usize,
}

pub fn get_thresholds(strict: bool) -> Thresholds {
    if strict {
        Thresholds { critical: 0, high: 0, medium: 1 }
    } else {
        Thresholds { critical: 0, high: 1, medium: 3 }
    }
}

pub fn should_block(counts: &HashMap<Severity, usize>, thresholds: &Thresholds) -> bool {
    *counts.get(&Severity::Critical).unwrap_or(&0) > thresholds.critical ||
    *counts.get(&Severity::High).unwrap_or(&0) > thresholds.high ||
    *counts.get(&Severity::Medium).unwrap_or(&0) > thresholds.medium
}

pub struct DecisionContext {
    pub violations: Vec<RuleViolation>,
    pub mode: String,
    pub strict: bool,
    pub dry_run: bool,
    pub circuit_breaker_tripped: bool,
}

pub fn make_decision(context: DecisionContext) -> MachineDecision {
    let thresholds = get_thresholds(context.strict);
    
    let mut counts = HashMap::new();
    for v in &context.violations {
        *counts.entry(v.severity.clone()).or_insert(0) += 1;
    }

    let mut reasons = Vec::new();
    let mut outcome = Outcome::Allow;

    if context.circuit_breaker_tripped {
        reasons.push("Circuit breaker tripped - too many blocks in current hour".to_string());
        outcome = Outcome::Warn;
    }

    if should_block(&counts, &thresholds) {
        reasons.push(format!(
            "Critical violations: {}, High: {}, Medium: {}",
            counts.get(&Severity::Critical).unwrap_or(&0),
            counts.get(&Severity::High).unwrap_or(&0),
            counts.get(&Severity::Medium).unwrap_or(&0)
        ));
        outcome = Outcome::Block;
    }

    if context.dry_run && matches!(outcome, Outcome::Block) {
        reasons.push("Dry-run mode: would block but allowing with warning".to_string());
        outcome = Outcome::Warn;
    }

    if matches!(outcome, Outcome::Allow) && context.violations.is_empty() {
        reasons.push("No violations detected".to_string());
    } else if matches!(outcome, Outcome::Allow) && !context.violations.is_empty() {
        reasons.push(format!("Minor violations within thresholds: Low: {}", counts.get(&Severity::Low).unwrap_or(&0)));
    }

    let mut metadata = HashMap::new();
    metadata.insert("timestamp".to_string(), serde_json::json!(Utc::now().to_rfc3339()));
    metadata.insert("mode".to_string(), serde_json::json!(context.mode));
    
    let rule_ids: Vec<String> = context.violations.iter().map(|v| v.rule_id.clone()).collect();
    let mut unique_rule_ids = rule_ids;
    unique_rule_ids.sort();
    unique_rule_ids.dedup();
    metadata.insert("rulesEvaluated".to_string(), serde_json::json!(unique_rule_ids));

    MachineDecision {
        outcome,
        reasons,
        metadata,
    }
}
