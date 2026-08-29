use universal_logic::csp::CspController;

#[test]
fn test_csp_contraction_and_gap() {
    let (slope_ub, gap_lb, is_contractive) = CspController::compute_contraction_bounds(0.5, 0.4);
    // SlopeUB = 0.5 + 0.5 * 0.4 = 0.70
    assert!((slope_ub - 0.70).abs() < 1e-6);
    // GapLB = 1 - 0.70 = 0.30
    assert!((gap_lb - 0.30).abs() < 1e-6);
    assert!(is_contractive);
}

#[test]
fn test_csp_fail_closed_on_expansive_operator() {
    let csp = CspController::new(0.5, 0.05);
    let initial = 0.5;
    // Operator with L_F = 3.0 (Expansive)
    let op = |x: f64| 3.0 * x;
    let proj = |x: f64| x.clamp(0.0, 1.0);

    let res = csp.step_1d(initial, op, 3.0, proj);
    assert!(res.is_err(), "Expansive operator must fail closed in CSP");
}
