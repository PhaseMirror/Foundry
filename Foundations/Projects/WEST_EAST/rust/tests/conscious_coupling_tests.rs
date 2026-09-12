use west_east::conscious_coupling::ConsciousnessCoupler;

#[test]
fn test_safety_gate_nominal_pass() {
    let delta_s = 0.20;
    let alpha = 0.04; // 0.04 < 0.05
    let res = ConsciousnessCoupler::evaluate_safety_gate(delta_s, alpha);
    assert!(res.is_ok());
    let report = res.unwrap();
    assert!(report.is_gate_passed);
    assert!(report.perturbed_gap_lb > delta_s / 2.0);
}

#[test]
fn test_safety_gate_overshoot_rejection() {
    let delta_s = 0.20;
    let alpha_overshoot = 0.06; // 0.06 >= 0.05
    let res = ConsciousnessCoupler::evaluate_safety_gate(delta_s, alpha_overshoot);
    assert!(res.is_err(), "Overshoot alpha must fail safety gate");
}
