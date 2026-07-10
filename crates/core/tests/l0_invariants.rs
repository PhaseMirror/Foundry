use nalgebra::{DMatrix, DVector};
use pirtm_rs::{step, EmissionGate, EmissionPolicy};

#[test]
fn test_l0_1_contractive_typing() {
    let dim = 2;
    let x = DVector::from_element(dim, 1.0);
    // Deliberately large gain matrices to force a projection (enforcing L0.1)
    let xi = DMatrix::from_element(dim, dim, 2.0);
    let lam = DMatrix::from_element(dim, dim, 2.0);
    let g = DVector::zeros(dim);
    let t_op = |v: &DVector<f64>| 0.8 * v;
    let p_op = |v: &DVector<f64>| v.clone();

    let epsilon = 0.05;
    let op_norm_t = 0.8;

    let (_, info) = step(&x, &xi, &lam, t_op, &g, p_op, epsilon, op_norm_t, 0);

    // L0.1 asserts q < 1 - epsilon.
    // Wait, the step function uses projection to *ensure* this.
    assert!(
        info.q <= 1.0 - epsilon + 1e-12,
        "L0.1 Contractive Typing violated: q = {}, limit = {}",
        info.q,
        1.0 - epsilon
    );
    assert!(info.projected, "Expected projection to enforce L0.1");
}

#[test]
fn test_l0_4_certified_emission() {
    let dim = 2;
    let x = DVector::from_element(dim, 1.0);
    let xi = DMatrix::from_element(dim, dim, 2.0); // Forces projection, q = 0.95
    let lam = DMatrix::from_element(dim, dim, 2.0);
    let g = DVector::zeros(dim);
    let t_op = |v: &DVector<f64>| 0.8 * v;
    let p_op = |v: &DVector<f64>| v.clone();

    let gate = EmissionGate::new(EmissionPolicy::Suppress, None, 0.01);

    let out = gate.call(&x, &xi, &lam, t_op, &g, p_op, 0.05, 0.8, 0);

    // L0.4: If EMIT is true, then ACE is certified (meaning q < 1 - epsilon without projection)
    // Since projection was triggered, it should be suppressed.
    assert!(
        !out.emitted,
        "L0.4 Certified Emission violated: emitted despite projection."
    );
}

#[test]
fn test_l0_2_and_l0_3_prime_ordering() {
    let mut ledger = pirtm_rs::PETCLedger::<()>::new(100, 1);

    // Test prime uniqueness and monotonicity
    let p1 = 2;
    let p2 = 3;
    let p3 = 5;

    assert!(ledger.append(p1, None, None).is_ok());
    assert!(ledger.append(p2, None, None).is_ok());
    assert!(ledger.append(p3, None, None).is_ok());

    let report = ledger.validate();
    assert!(
        report.satisfied,
        "L0.2 and L0.3 Prime Ordering violated: report not satisfied"
    );
    assert!(report.monotonic, "L0.3 Prime Monotonicity violated");
}
