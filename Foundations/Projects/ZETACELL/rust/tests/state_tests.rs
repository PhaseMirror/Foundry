use zetacell::state::ZetaState;

#[test]
fn test_zeta_state_norm_and_distance() {
    let mut s1 = ZetaState::new(4, 2, 4, 2);
    for x in &mut s1.psi {
        *x = 1.0;
    }
    for x in &mut s1.chi {
        *x = 2.0;
    }

    // psi norm sq: 4 * 2 * 1 = 8
    // chi norm sq: 4 * 2 * 4 = 32
    // total norm: sqrt(40)
    let expected_norm = (40.0f64).sqrt();
    assert!((s1.norm() - expected_norm).abs() < 1e-6);

    let s2 = ZetaState::new(4, 2, 4, 2);
    assert!((s1.distance(&s2) - expected_norm).abs() < 1e-6);
}
