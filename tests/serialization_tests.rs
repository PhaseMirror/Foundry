// Serialization tests: round-trip serde for governance types.
// Ensures that types survive JSON serialization/deserialization without data loss.

#[cfg(test)]
mod tests {
    use multiplicity_common::constitution::{L0Invariant, ConstitutionViolation, ConstitutionModel, PrimeGate, CritiqueResult};
    use multiplicity_common::types::{TrustLevel, VetoStatus, SpoliationRiskLevel};

    #[test]
    fn l0_invariant_round_trip() {
        let invariants = vec![
            L0Invariant::L0_1,
            L0Invariant::L0_5,
            L0Invariant::L0_10,
        ];
        for inv in &invariants {
            let json = serde_json::to_string(inv).unwrap();
            let deserialized: L0Invariant = serde_json::from_str(&json).unwrap();
            assert_eq!(*inv, deserialized);
        }
    }

    #[test]
    fn l0_invariant_json_format() {
        assert_eq!(serde_json::to_string(&L0Invariant::L0_1).unwrap(), r#""L0-1""#);
        assert_eq!(serde_json::to_string(&L0Invariant::L0_9).unwrap(), r#""L0-9""#);
    }

    #[test]
    fn trust_level_round_trip() {
        let levels = vec![TrustLevel::Internal, TrustLevel::External];
        for level in &levels {
            let json = serde_json::to_string(level).unwrap();
            let deserialized: TrustLevel = serde_json::from_str(&json).unwrap();
            assert_eq!(*level, deserialized);
        }
    }

    #[test]
    fn trust_level_json_format() {
        assert_eq!(serde_json::to_string(&TrustLevel::Internal).unwrap(), r#""internal""#);
        assert_eq!(serde_json::to_string(&TrustLevel::External).unwrap(), r#""external""#);
    }

    #[test]
    fn veto_status_round_trip() {
        let statuses = vec![
            VetoStatus::Approved,
            VetoStatus::Vetoed("reason".to_string()),
            VetoStatus::Pending,
        ];
        for status in &statuses {
            let json = serde_json::to_string(status).unwrap();
            let deserialized: VetoStatus = serde_json::from_str(&json).unwrap();
            assert_eq!(*status, deserialized);
        }
    }

    #[test]
    fn veto_status_json_format() {
        assert_eq!(serde_json::to_string(&VetoStatus::Approved).unwrap(), r#""approved""#);
        assert_eq!(serde_json::to_string(&VetoStatus::Pending).unwrap(), r#""pending""#);
        let vetoed = VetoStatus::Vetoed("test".to_string());
        let json = serde_json::to_string(&vetoed).unwrap();
        assert!(json.contains("vetoed"));
        assert!(json.contains("test"));
    }

    #[test]
    fn spoliation_risk_level_round_trip() {
        let levels = vec![
            SpoliationRiskLevel::Critical,
            SpoliationRiskLevel::High,
            SpoliationRiskLevel::Medium,
            SpoliationRiskLevel::Low,
        ];
        for level in &levels {
            let json = serde_json::to_string(level).unwrap();
            let deserialized: SpoliationRiskLevel = serde_json::from_str(&json).unwrap();
            assert_eq!(*level, deserialized);
        }
    }

    #[test]
    fn constitution_violation_round_trip() {
        let violation = ConstitutionViolation {
            invariant: L0Invariant::L0_3,
            detail: "Schema validation failed".to_string(),
        };
        let json = serde_json::to_string(&violation).unwrap();
        let deserialized: ConstitutionViolation = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.invariant, L0Invariant::L0_3);
        assert_eq!(deserialized.detail, "Schema validation failed");
    }

    #[test]
    fn prime_gate_round_trip() {
        let gate = PrimeGate {
            action_name: "deploy".to_string(),
            gate_value: 42,
        };
        let json = serde_json::to_string(&gate).unwrap();
        let deserialized: PrimeGate = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.action_name, "deploy");
        assert_eq!(deserialized.gate_value, 42);
    }

    #[test]
    fn critique_result_round_trip() {
        let result = CritiqueResult {
            critique_id: 3,
            passed: true,
            reason: None,
        };
        let json = serde_json::to_string(&result).unwrap();
        let deserialized: CritiqueResult = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.critique_id, 3);
        assert!(deserialized.passed);
        assert!(deserialized.reason.is_none());
    }

    #[test]
    fn constitution_model_round_trip() {
        let model = ConstitutionModel {
            state_norm: 0.85,
            drift_rate: 0.02,
            dynamic_lambda_m: Some(0.3),
            critique_results: vec![CritiqueResult {
                critique_id: 0,
                passed: true,
                reason: None,
            }],
            prime_gates: vec![PrimeGate {
                action_name: "test".to_string(),
                gate_value: 1,
            }],
            contractivity_score: 0.95,
            kill_switch_active: false,
            rollback_anchor_sha: Some("abc123".to_string()),
            proof_anchor: None,
            audit_warnings: vec![],
            active_anchors: vec![],
            consecutive_failures: 0,
            civic_state: Some(1.5),
        };
        let json = serde_json::to_string(&model).unwrap();
        let deserialized: ConstitutionModel = serde_json::from_str(&json).unwrap();
        assert!((deserialized.state_norm - 0.85).abs() < f64::EPSILON);
        assert!((deserialized.contractivity_score - 0.95).abs() < f64::EPSILON);
        assert!(!deserialized.kill_switch_active);
        assert_eq!(deserialized.critique_results.len(), 1);
        assert_eq!(deserialized.prime_gates.len(), 1);
        assert_eq!(deserialized.consecutive_failures, 0);
    }

    #[test]
    fn deserialization_rejects_invalid_variant() {
        let result = serde_json::from_str::<TrustLevel>(r#""banana""#);
        assert!(result.is_err(), "Invalid variant should fail deserialization");
    }

    #[test]
    fn deserialization_rejects_invalid_json() {
        let result = serde_json::from_str::<L0Invariant>("not json at all");
        assert!(result.is_err(), "Malformed JSON should fail deserialization");
    }
}
