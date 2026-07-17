use ace_governance::*;

#[test]
fn test_parity_mode_converges() {
    let layer = ACEGovernanceLayer::new(TelemetrySource::PhaseMirrorKernel, true);
    
    // Benchmark state
    let state = StepState { xn: 0.15 };
    
    // get_drift_metrics internally asserts parity tolerance (< 1e-9)
    let kt = layer.get_drift_metrics(&state).unwrap();
    
    assert_eq!(kt.xn_kernel, 0.15);
    assert_eq!(kt.wt_max_kernel, 0.0);
    assert_eq!(kt.protection_zeta, 0.0);
}

#[test]
fn test_deprecated_authority_fails() {
    let layer = ACEGovernanceLayer::new(TelemetrySource::LegacyACE, true);
    let state = StepState { xn: 0.15 };
    
    let res = layer.get_drift_metrics(&state);
    assert!(matches!(res, Err(GovernanceError::DeprecatedAuthority)));
}
