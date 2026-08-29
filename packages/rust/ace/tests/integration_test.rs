use ace::*;

#[test]
fn test_wac_certification_valid() {
    let wac = WacCertification::new("test-state", 0.5, 0.0, 0.0);
    assert!(wac.is_contracting);
    assert!(wac.verify().is_ok());
}

#[test]
fn test_wac_certification_violates_lipschitz() {
    let wac = WacCertification::new("test-state", 1.5, 0.0, 0.0);
    assert!(!wac.is_contracting);
    assert!(wac.verify().is_err());
}

#[test]
fn test_dse_certification_valid() {
    let dse = DseCertification::new("test-state", 0.01, 0, 0.03, 10);
    assert!(dse.is_within_bounds);
    assert!(dse.verify().is_ok());
}

#[test]
fn test_dse_certification_drift_exceeded() {
    let dse = DseCertification::new("test-state", 0.05, 0, 0.03, 10);
    assert!(!dse.is_within_bounds);
    assert!(dse.verify().is_err());
}

#[test]
fn test_dse_certification_sparse_expansion() {
    let dse = DseCertification::new("test-state", 0.01, 20, 0.03, 10);
    assert!(!dse.is_within_bounds);
    assert!(dse.verify().is_err());
}

#[test]
fn test_circuit_budget() {
    let mut budget = CircuitBudget::new(5_087);
    assert!(budget.consume(100).is_ok());
    assert_eq!(budget.remaining(), 4_987);

    let result = budget.consume(6_000);
    assert!(result.is_err());
}

#[test]
fn test_certification_params_defaults() {
    let params = CertificationParams::default();
    assert_eq!(params.lipschitz_bound, 1.0);
    assert_eq!(params.max_drift, 0.03);
    assert_eq!(params.r1cs_budget, 5_087);
}

#[test]
fn test_sig_gov_kill() {
    let kill = SigGovKill::trigger("Lipschitz bound violated", "state-001");
    assert_eq!(kill.reason, "Lipschitz bound violated");
    assert_eq!(kill.audit_trail.len(), 1);
}
