pub mod schemas;
pub mod policy;
pub mod rules;
pub mod clinical_rules;

pub use schemas::*;
pub use policy::*;
pub use rules::*;
pub use clinical_rules::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_clinical_dissonance_report() {
        let input = ClinicalWorkflowInput {
            patient_id: "PAT-001".to_string(),
            procedure_code: "72148".to_string(),
            justification_anchored: false, // Critical Violation
            confidence_score: 0.92,       // High Violation
            execution_epoch: 100,         // High Violation (Not prime)
            stability_score: 0.85,        // Ok
        };

        let violations = check_clinical_dissonance(&input);
        assert_eq!(violations.len(), 3);
        
        let context = DecisionContext {
            violations,
            mode: "clinical_pilot".to_string(),
            strict: true,
            dry_run: false,
            circuit_breaker_tripped: false,
        };

        let decision = make_decision(context);
        assert!(matches!(decision.outcome, Outcome::Block));
        println!("Clinical Decision Outcome: {:?}", decision.outcome);
        for reason in decision.reasons {
            println!("  Reason: {}", reason);
        }
    }
}
