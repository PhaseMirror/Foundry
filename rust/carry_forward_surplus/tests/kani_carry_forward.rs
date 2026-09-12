#[cfg(kani)]
#[kani::proof]
#[kani::unwind(64)]
fn check_kernel_symmetry() {
    let delta: f64 = kani::any();
    let beta: f64 = kani::any();
    // constrain beta positive and reasonable range to avoid overflow
    kani::assume(beta > 0.0 && beta < 10.0);
    // no constraints on delta magnitude for this test
    let k1 = carry_forward_surplus::kernel(delta, beta);
    let k2 = carry_forward_surplus::kernel(-delta, beta);
    // kernel should be odd: k(-d) = -k(d)
    const EPS: f64 = 1e-12;
    assert!((k1 + k2).abs() < EPS);
}

#[cfg(kani)]
#[kani::proof]
#[kani::unwind(64)]
fn check_update_conservation_lambda_one() {
    let sx: f64 = kani::any();
    let sy: f64 = kani::any();
    let beta: f64 = kani::any();
    kani::assume(beta > 0.0 && beta < 10.0);
    let lam: f64 = 1.0;
    let (sx_n, sy_n) = carry_forward_surplus::update(sx, sy, beta, lam);
    const EPS: f64 = 1e-12;
    assert!(((sx + sy) - (sx_n + sy_n)).abs() < EPS);
}

#[cfg(kani)]
#[kani::proof]
#[kani::unwind(64)]
fn check_update_decay_lambda_half() {
    let sx: f64 = kani::any();
    let sy: f64 = kani::any();
    let beta: f64 = kani::any();
    kani::assume(beta > 0.0 && beta < 10.0);
    let lam: f64 = 0.5;
    let (sx_n, sy_n) = carry_forward_surplus::update(sx, sy, beta, lam);
    const EPS: f64 = 1e-12;
    // total should be scaled by lam
    assert!(((sx_n + sy_n) - lam * (sx + sy)).abs() < EPS);
}
