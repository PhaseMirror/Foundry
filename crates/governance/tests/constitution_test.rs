use governance_core_rs::{ConstitutionModel, CritiqueResult, PrimeGate, ConstitutionError};

fn valid_model() -> ConstitutionModel {
    ConstitutionModel {
        state_norm: 1.0,
        drift_rate: 0.05,
        dynamic_lambda_m: None,
        critique_results: (0..10).map(|i| CritiqueResult { critique_id: i, passed: true, reason: None }).collect(),
        prime_gates: vec![PrimeGate { action_name: "test".to_string(), gate_value: 17 }],
        contractivity_score: 0.9,
        kill_switch_active: false,
        rollback_anchor_sha: Some("abc".to_string()),
        proof_anchor: Some("0x0000000000000000000000000000000000000000000000000000000000000000".to_string()),
        audit_warnings: vec![],
        active_anchors: vec!["0x0000000000000000000000000000000000000000000000000000000000000000".to_string()],
        consecutive_failures: 0,
    }
}

#[test]
fn test_constitution_valid() {
    let mut model = valid_model();
    assert!(model.validate().is_ok());
}

#[test]
fn test_l0_2_drift_violation() {
    let mut model = valid_model();
    model.drift_rate = 0.2; // > 0.1
    let res = model.validate();
    assert!(res.is_err());
    if let Err(ConstitutionError::Violation { invariant, .. }) = res {
        assert_eq!(invariant, "L0-2");
    }
}

#[test]
fn test_l0_4_prime_violation() {
    let mut model = valid_model();
    model.prime_gates[0].gate_value = 16; // Not prime
    let res = model.validate();
    assert!(res.is_err());
    if let Err(ConstitutionError::Violation { invariant, .. }) = res {
        assert_eq!(invariant, "L0-4");
    }
}

#[test]
fn test_l0_6_kill_switch() {
    let mut model = valid_model();
    model.kill_switch_active = true;
    let res = model.validate();
    assert!(res.is_err());
    if let Err(ConstitutionError::Violation { invariant, .. }) = res {
        assert_eq!(invariant, "L0-6");
    }
}
