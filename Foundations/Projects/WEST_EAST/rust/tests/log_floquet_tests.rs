use west_east::log_floquet::LogFloquetPropagator;

#[test]
fn test_log_floquet_zero_modulation_zero_drift() {
    let (actual_drift, bound) = LogFloquetPropagator::compute_seasonal_drift(0.0, 1.0, 10.0, 0.0, 100);
    assert!(actual_drift < 1e-6);
    assert_eq!(bound, 0.0);
}

#[test]
fn test_log_floquet_drift_bound() {
    let epsilon = 0.005;
    let t = 20.0;
    let (actual_drift, bound) = LogFloquetPropagator::compute_seasonal_drift(0.0, 1.0, t, epsilon, 200);
    assert!(actual_drift <= bound + 1e-4, "Observed drift must be within theoretical bound");
}
