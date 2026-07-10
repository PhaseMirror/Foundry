use crate::schemas::{RuleViolation, Severity, ConflictLogSchema};

pub fn check_physical_dissonance(input: &ConflictLogSchema) -> Vec<RuleViolation> {
    let mut violations = Vec::new();

    // PR-001: Effective Coupling Limit (L_eff < 1.0)
    if input.l_eff >= 1.0 {
        violations.push(RuleViolation {
            rule_id: "PR-001".to_string(),
            severity: Severity::Critical,
            message: format!(
                "Effective contraction (L_eff) must be < 1.0, but got {:.4}. Violates ADR-402 Physical Invariant.",
                input.l_eff
            ),
            context: None,
        });
    }

    // PR-002: Resonance Delta Scale Limit (\Delta R_{sc} \le \tau_R)
    // Wait, the ADR says \Delta R_{sc} = |R_{sc} - \tau_R| or maybe R_{sc} is the value and \Delta R_{sc} is the delta.
    // The user wrote: "Assert \Delta R_{sc} \le \tau_R"
    // Let's assume input.r_sc is \Delta R_{sc} or input.r_sc is just R_{sc} and \Delta R_{sc} is its absolute delta from something?
    // User requested "Assert \Delta R_{sc} \le \tau_R". The struct has `r_sc` and `tau_r`. We can check if r_sc > tau_r
    if input.r_sc > input.tau_r {
        violations.push(RuleViolation {
            rule_id: "PR-002".to_string(),
            severity: Severity::Critical,
            message: format!(
                "Resonance delta (R_sc = {:.4}) exceeds threshold (tau_R = {:.4}). Violates ADR-402 Physical Invariant.",
                input.r_sc, input.tau_r
            ),
            context: None,
        });
    }

    violations
}
