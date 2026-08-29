use zetacell::projectors::ProjectorEngine;
use zetacell::state::ZetaState;

#[test]
fn test_csl_row_norm_capping() {
    let mut state = ZetaState::new(2, 2, 2, 2);
    // Set first row norm to 10.0 (large)
    state.psi[0] = 6.0;
    state.psi[1] = 8.0;

    ProjectorEngine::csl_project(&mut state, 5.0, 0.0);

    let new_norm = (state.psi[0] * state.psi[0] + state.psi[1] * state.psi[1]).sqrt();
    assert!((new_norm - 5.0).abs() < 1e-6, "Row norm must be clamped to 5.0");
}

#[test]
fn test_ethical_projector_entropy() {
    let mut state = ZetaState::new(4, 2, 4, 2);
    for x in &mut state.psi {
        *x = 1.0;
    }
    for x in &mut state.chi {
        *x = 1.0;
    }

    let (hp, hz) = ProjectorEngine::ethical_project(&mut state, 2.0);
    assert!(hp > 0.0);
    assert!(hz > 0.0);
}
